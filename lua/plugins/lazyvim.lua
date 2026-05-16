-- LazyVim baseline layered onto the existing 4-pane custom IDE layout.
-- Brings in theming (tokyonight), snacks ecosystem, LSP + Mason, treesitter,
-- which-key, telescope, gitsigns, conform, mini.*, flash, todo-comments,
-- nvim-cmp/blink, trouble, noice, lualine, bufferline, and friends.
--
-- Two tweaks keep the existing layout intact:
--   1. Snacks dashboard is disabled — VimEnter in lua/config/layout.lua opens
--      the task panel + bottom terminals on startup; no dashboard needed.
--   2. User keymaps are re-applied after LazyVim's VeryLazy keymap loader so
--      the <leader>k / <leader>t* bindings always win on conflict.

-- The `import = "lazyvim.plugins"` directive lives in init.lua so LazyVim's
-- startup order check passes. This file only overlays per-plugin tweaks.
return {
  {
    "LazyVim/LazyVim",
    priority = 10000,
    lazy = false,
    opts = {},
    config = function(_, opts)
      require("lazyvim").setup(opts)
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          package.loaded["config.keymaps"] = nil
          require("config.keymaps")
        end,
      })
    end,
  },

  {
    "folke/snacks.nvim",
    opts = { dashboard = { enabled = false } },
  },
}
