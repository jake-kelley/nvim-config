-- Layout-specific keymaps. <leader>e is registered by the neo-tree plugin spec.
local layout = require("config.layout")
local map = vim.keymap.set

local TAG_VAR = "cowork_layout_kind"

local function find_win_by_tag(tag)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ok, val = pcall(vim.api.nvim_buf_get_var, buf, TAG_VAR)
      if ok and val == tag then return win end
    end
  end
end

-- Toggle focus: jump to task panel, or back to previous window if already there.
map("n", "<leader>k", function()
  local win = find_win_by_tag("tasks")
  if not win then
    layout.open_task_panel()
    return
  end
  if vim.api.nvim_get_current_win() == win then
    vim.cmd("wincmd p")
  else
    vim.api.nvim_set_current_win(win)
  end
end, { desc = "Toggle focus: task panel" })

local function focus_term(tag)
  local win = find_win_by_tag(tag)
  if not win then
    vim.notify("Terminal '" .. tag .. "' not found in layout", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert")
end

map("n", "<leader>tc", function() focus_term("claude") end, { desc = "Focus Claude Code" })
map("n", "<leader>ts", function() focus_term("shell") end,  { desc = "Focus shell"        })

-- Easier escape from terminal insert mode.
map("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Exit terminal insert mode" })

-- Quick-add a task to the ## Todo section of tasks.md.
map("n", "<leader>ta", function()
  vim.ui.input({ prompt = "New task: " }, function(input)
    if not input or input == "" then return end
    local tasks_file = layout.tasks_file()
    local lines = vim.fn.readfile(tasks_file)
    local inserted = false
    for i, line in ipairs(lines) do
      if line:match("^##.*Todo%s*$") then
        table.insert(lines, i + 1, "- [ ] " .. input)
        inserted = true
        break
      end
    end
    if not inserted then
      table.insert(lines, "## 📝 Todo")
      table.insert(lines, "- [ ] " .. input)
    end
    vim.fn.writefile(lines, tasks_file)
    vim.cmd("checktime")
  end)
end, { desc = "Add task to Todo" })

-- Move the task on the current line to a different section.
-- Only works inside the task panel buffer. Done flips checkbox to [x]; others reset to [ ].
local function move_task_to_section(target)
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, kind = pcall(vim.api.nvim_buf_get_var, bufnr, TAG_VAR)
  if not ok or kind ~= "tasks" then
    vim.notify("Move task: not in task panel", vim.log.levels.WARN)
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local body = line:match("^%s*%- %[[ xX]%]%s*(.*)$")
  if not body or body == "" then
    vim.notify("Move task: cursor not on a task line", vim.log.levels.WARN)
    return
  end
  local checkbox = (target == "Done") and "[x]" or "[ ]"
  local new_line = "- " .. checkbox .. " " .. body
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, {})
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local header_idx
  for i, l in ipairs(lines) do
    if l:match("^##.*" .. target .. "%s*$") then
      header_idx = i
      break
    end
  end
  if not header_idx then
    vim.notify("Move task: section '" .. target .. "' not found", vim.log.levels.WARN)
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum - 1, false, { line })
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, header_idx, header_idx, false, { new_line })
end

map("n", "<leader>td", function() move_task_to_section("Done") end,        { desc = "Task: mark done" })
map("n", "<leader>tb", function() move_task_to_section("Blocked") end,     { desc = "Task: move to blocked" })
map("n", "<leader>tp", function() move_task_to_section("In Progress") end, { desc = "Task: move to in progress" })
map("n", "<leader>tt", function() move_task_to_section("Todo") end,        { desc = "Task: move to todo" })
