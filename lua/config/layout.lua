-- Persistent IDE layout:
--   filetree (toggle) | editor | task panel (always on)
--   bottom row: claude code (50%) | shell (50%)
-- Tasks live at stdpath('data')/tasks.md (plain markdown, single source of truth).

local M = {}

local TASKS_FILE       = vim.fn.stdpath("data") .. "/tasks.md"
-- 25% panel shrunk by 25% → 0.1875 of total columns.
local TASK_PANEL_WIDTH = 0.1875
-- 25% panel bumped up by another 25% → 0.3125 of total lines.
local TERMINAL_HEIGHT  = 0.3125

-- Buffer-local tag so we can find managed buffers reliably.
local TAG_VAR = "cowork_layout_kind"  -- "tasks" | "claude" | "shell"

local function find_win_by_tag(tag)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ok, val = pcall(vim.api.nvim_buf_get_var, buf, TAG_VAR)
      if ok and val == tag then return win, buf end
    end
  end
  return nil, nil
end

-- Buffer-only lookup; finds tagged buffers even when not currently visible.
local function find_buf_by_tag(tag)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, val = pcall(vim.api.nvim_buf_get_var, buf, TAG_VAR)
      if ok and val == tag then return buf end
    end
  end
end

local function tag_current_buf(tag)
  vim.api.nvim_buf_set_var(0, TAG_VAR, tag)
end

local TASK_TEMPLATE = table.concat({
  "# Tasks",
  "",
  "## 📝 Todo",
  "- [ ] Example task",
  "",
  "## 🔄 In Progress",
  "- [ ] ",
  "",
  "## 🚫 Blocked",
  "- [ ] ",
  "",
  "## ✅ Done",
  "- [x] Set up Neovim layout",
  "",
}, "\n")

-- Returns { lnum, checkbox, body } for a task line under the cursor, or nil.
-- Matches `- [ ] ...`, `- [x] ...`, `- [X] ...` (any indent, body may be empty).
local function get_task_info()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local checkbox, body = line:match("^%s*%- %[([ xX])%]%s*(.*)$")
  if not checkbox then return nil end
  return { lnum = lnum, checkbox = checkbox, body = body or "" }
end

local function task_move_to(target)
  local t = get_task_info()
  if not t then
    vim.notify("Not on a task line", vim.log.levels.WARN)
    return
  end
  local checkbox = (target == "Done") and "[x]" or "[ ]"
  local new_line = "- " .. checkbox .. " " .. t.body
  vim.api.nvim_buf_set_lines(0, t.lnum - 1, t.lnum, false, {})
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local hdr
  for i, l in ipairs(lines) do
    if l:match("^##.*" .. target .. "%s*$") then hdr = i; break end
  end
  if not hdr then
    vim.notify("Section '" .. target .. "' not found", vim.log.levels.WARN)
    vim.api.nvim_buf_set_lines(0, t.lnum - 1, t.lnum - 1, false, { new_line })
    return
  end
  vim.api.nvim_buf_set_lines(0, hdr, hdr, false, { new_line })
end

local function task_new()
  vim.ui.input({ prompt = "New task: " }, function(input)
    if not input or input == "" then return end
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, l in ipairs(lines) do
      if l:match("^##.*Todo%s*$") then
        vim.api.nvim_buf_set_lines(0, i, i, false, { "- [ ] " .. input })
        return
      end
    end
    vim.notify("Todo section not found", vim.log.levels.WARN)
  end)
end

local function task_delete()
  local t = get_task_info()
  if not t then
    vim.notify("Not on a task line", vim.log.levels.WARN)
    return
  end
  local label = (t.body ~= "" and t.body) or "(empty)"
  vim.ui.input({ prompt = "Delete task '" .. label .. "'? (y/N): " }, function(input)
    if input and input:lower() == "y" then
      vim.api.nvim_buf_set_lines(0, t.lnum - 1, t.lnum, false, {})
    end
  end)
end

local function task_rename()
  local t = get_task_info()
  if not t then
    vim.notify("Not on a task line", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "Rename task: ", default = t.body }, function(input)
    if not input then return end
    local new_line = "- [" .. t.checkbox .. "] " .. input
    vim.api.nvim_buf_set_lines(0, t.lnum - 1, t.lnum, false, { new_line })
  end)
end

local function ensure_tasks_file()
  if vim.fn.filereadable(TASKS_FILE) == 0 then
    local f = io.open(TASKS_FILE, "w")
    if f then f:write(TASK_TEMPLATE); f:close() end
  end
end

local function open_task_panel()
  if find_win_by_tag("tasks") then return end
  vim.cmd("botright vsplit " .. vim.fn.fnameescape(TASKS_FILE))
  local width = math.max(30, math.floor(vim.o.columns * TASK_PANEL_WIDTH))
  vim.cmd("vertical resize " .. width)

  tag_current_buf("tasks")
  vim.wo.winfixwidth    = true
  vim.wo.number         = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn     = "no"
  vim.wo.wrap           = true
  vim.bo.filetype       = "markdown"

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd(
    { "TextChanged", "TextChangedI", "InsertLeave", "BufLeave", "FocusLost" },
    {
      buffer = buf,
      group = vim.api.nvim_create_augroup("CoworkTaskAutoSave_" .. buf, { clear = true }),
      callback = function()
        if vim.bo[buf].modified then
          pcall(vim.api.nvim_buf_call, buf, function() vim.cmd("silent! write") end)
        end
      end,
    }
  )

  -- Buffer-local single-key task ops. nowait = true so `d` fires immediately
  -- instead of waiting for a motion (Vim's default `d` is an operator).
  local function bmap(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc, silent = true, nowait = true })
  end
  bmap("b", function() task_move_to("Blocked")     end, "Task: move to Blocked")
  bmap("d", function() task_move_to("Done")        end, "Task: move to Done")
  bmap("p", function() task_move_to("In Progress") end, "Task: move to In Progress")
  bmap("n", task_new,    "Task: new (under Todo)")
  bmap("x", task_delete, "Task: delete (confirm)")
  bmap("r", task_rename, "Task: rename")
end

local function start_claude_terminal()
  vim.cmd("terminal claude --dangerously-skip-permissions")
  tag_current_buf("claude")
  vim.bo.bufhidden = "wipe"
  pcall(vim.api.nvim_buf_set_name, 0, "term://claude-code")
end

local function start_shell_terminal()
  -- PowerShell 7 (`pwsh`) instead of cmd. -NoLogo skips the banner.
  vim.cmd("terminal pwsh -NoLogo")
  tag_current_buf("shell")
  vim.bo.bufhidden = "wipe"
  pcall(vim.api.nvim_buf_set_name, 0, "term://pwsh")
end

local function open_bottom_terminals()
  vim.cmd("botright split")
  local height = math.max(8, math.floor(vim.o.lines * TERMINAL_HEIGHT))
  vim.cmd("resize " .. height)
  vim.wo.winfixheight = true

  start_claude_terminal()

  vim.cmd("vsplit")
  vim.wo.winfixheight = true
  start_shell_terminal()

  vim.cmd("wincmd =")
end

local function focus_editor()
  vim.cmd("wincmd t")
end

local function reapply_proportions()
  local tw = find_win_by_tag("tasks")
  if tw then
    local width = math.max(30, math.floor(vim.o.columns * TASK_PANEL_WIDTH))
    pcall(vim.api.nvim_win_set_width, tw, width)
  end
  local cw = find_win_by_tag("claude")
  if cw then
    local height = math.max(8, math.floor(vim.o.lines * TERMINAL_HEIGHT))
    pcall(vim.api.nvim_win_set_height, cw, height)
  end
  local sw = find_win_by_tag("shell")
  if cw and sw then
    local total = vim.api.nvim_win_get_width(cw) + vim.api.nvim_win_get_width(sw)
    local half = math.floor(total / 2)
    pcall(vim.api.nvim_win_set_width, cw, half)
    pcall(vim.api.nvim_win_set_width, sw, total - half)
  end
end

local function on_term_close(args)
  local buf = args.buf
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local ok, kind = pcall(vim.api.nvim_buf_get_var, buf, TAG_VAR)
  if not ok or kind ~= "claude" then return end

  local target_win
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      target_win = win
      break
    end
  end
  if not target_win then return end

  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(target_win) then return end
    vim.api.nvim_set_current_win(target_win)
    start_claude_terminal()
  end)
end

local function on_vim_leave_pre()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

-- Captures tasks/claude/shell widths right before a neo-tree toggle so
-- they can be restored verbatim after. The editor (untagged) absorbs the
-- delta. This is the *only* mechanism keeping the layout stable across
-- toggles -- do not rely on winfixwidth alone, Vim doesn't always honor it
-- when a sibling opens or closes.
local toggle_snapshot = nil

local function snapshot_for_toggle()
  toggle_snapshot = {}
  for _, tag in ipairs({ "tasks", "claude", "shell" }) do
    local win = find_win_by_tag(tag)
    if win then
      toggle_snapshot[tag] = {
        width  = vim.api.nvim_win_get_width(win),
        height = vim.api.nvim_win_get_height(win),
      }
    end
  end
end

local function restore_after_toggle()
  if not toggle_snapshot then return end
  -- Set heights first (bottom row), then widths -- order matters because
  -- Vim recomputes neighbors on each call.
  for _, tag in ipairs({ "claude", "shell" }) do
    local dims = toggle_snapshot[tag]
    local win  = find_win_by_tag(tag)
    if win and dims and dims.height then
      pcall(vim.api.nvim_win_set_height, win, dims.height)
    end
  end
  for _, tag in ipairs({ "tasks", "claude", "shell" }) do
    local dims = toggle_snapshot[tag]
    local win  = find_win_by_tag(tag)
    if win and dims and dims.width then
      pcall(vim.api.nvim_win_set_width, win, dims.width)
    end
  end
  toggle_snapshot = nil
end

function M.open_task_panel() open_task_panel() end
function M.tasks_file() return TASKS_FILE end
function M.reapply_proportions() reapply_proportions() end
function M.snapshot_for_toggle() snapshot_for_toggle() end
function M.restore_after_toggle() restore_after_toggle() end

function M.setup()
  ensure_tasks_file()
  vim.o.autoread = true
  local grp = vim.api.nvim_create_augroup("CoworkLayout", { clear = true })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    group = grp,
    pattern = "*",
    callback = function() pcall(vim.cmd, "checktime") end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = grp,
    callback = function() vim.schedule(reapply_proportions) end,
  })

  -- Entering claude / shell panes drops straight into terminal-job mode and
  -- pins the view to the live output line (no manual `i`, no scrollback).
  -- Filters by our own TAG_VAR so plugin/lazy/mason terminal buffers (which
  -- the user may want to scroll through) are not hijacked.
  vim.api.nvim_create_autocmd("WinEnter", {
    group = grp,
    callback = function()
      if vim.bo.buftype ~= "terminal" then return end
      local ok, tag = pcall(vim.api.nvim_buf_get_var, 0, TAG_VAR)
      if not ok or (tag ~= "claude" and tag ~= "shell") then return end
      vim.cmd("startinsert")
    end,
  })

  -- Mirror Neovim :cd / :lcd / :tcd into the shell terminal. Claude is left
  -- alone -- its CWD is set at launch and can't change without a restart.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = grp,
    pattern = "*",
    callback = function()
      local cwd = (vim.v.event and vim.v.event.cwd) or vim.fn.getcwd()
      if not cwd or cwd == "" then return end
      local buf = find_buf_by_tag("shell")
      if not buf then return end
      local job_id = vim.b[buf].terminal_job_id
      if not job_id then return end
      -- PowerShell single-quoted strings are literal; double any embedded
      -- quotes to escape. Set-Location -LiteralPath handles brackets, $, etc.
      local escaped = cwd:gsub("'", "''")
      pcall(vim.api.nvim_chan_send, job_id,
        "Set-Location -LiteralPath '" .. escaped .. "'\r")
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = grp,
    callback = on_term_close,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = grp,
    callback = on_vim_leave_pre,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = grp,
    once = true,
    callback = function()
      vim.schedule(function()
        local user_opened_files = vim.fn.argc() > 0
        open_task_panel()
        open_bottom_terminals()
        focus_editor()
        if user_opened_files then
          vim.cmd("wincmd t")
        end
      end)
    end,
  })
end

return M
