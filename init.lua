-- Neovim IDE layout entrypoint.
-- See lua/config/layout.lua for the four-pane setup.

-- Set <leader> BEFORE lazy.nvim loads so plugin keymaps inherit it.
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- sane defaults
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.signcolumn     = "yes"
vim.opt.termguicolors  = true
vim.opt.splitbelow     = true
vim.opt.splitright     = true
-- Don't auto-equalize remaining windows when a split opens/closes.
-- The neo-tree toggle relies on the editor (the only non-fixed window)
-- to absorb the width delta; equalalways=true breaks that.
vim.opt.equalalways    = false
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 2
vim.opt.tabstop        = 2
vim.opt.smartindent    = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.updatetime     = 250
vim.opt.scrolloff      = 4
vim.opt.confirm        = true
vim.opt.autoread       = true

-- Plugin load order is enforced by LazyVim: lazyvim.plugins first, then any
-- lazyvim.plugins.extras.*, then user's own plugins/. Keep this order or
-- LazyVim's check_order will throw at startup.
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Add `{ import = "lazyvim.plugins.extras.xxx" }` lines here when needed.
    { import = "plugins" },
  },
  change_detection = { notify = false },
})

-- layout + keymaps
require("config.layout").setup()
require("config.keymaps")
