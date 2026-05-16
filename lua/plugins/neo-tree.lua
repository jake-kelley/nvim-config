-- File tree on the left, hidden by default, toggled with <leader>e.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    {
      "<leader>e",
      function()
        -- Snapshot tasks/claude/shell widths BEFORE neo-tree changes the layout,
        -- so the after_open / after_close handlers can restore them exactly.
        local ok, layout = pcall(require, "config.layout")
        if ok then layout.snapshot_for_toggle() end
        vim.cmd("Neotree toggle")
      end,
      desc = "Toggle file tree",
    },
  },
  opts = {
    close_if_last_window = false,
    window = {
      position = "left",
      width = function() return math.max(20, math.floor(vim.o.columns * 0.20)) end,
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
    },
    event_handlers = {
      {
        event = "neo_tree_window_after_open",
        handler = function(args)
          local winid = args and args.winid
          if winid and vim.api.nvim_win_is_valid(winid) then
            pcall(vim.api.nvim_win_set_option, winid, "winfixwidth", true)
          end
          vim.schedule(function()
            local ok, layout = pcall(require, "config.layout")
            if ok then layout.restore_after_toggle() end
          end)
        end,
      },
      {
        event = "neo_tree_window_after_close",
        handler = function()
          vim.schedule(function()
            local ok, layout = pcall(require, "config.layout")
            if ok then layout.restore_after_toggle() end
          end)
        end,
      },
    },
  },
}
