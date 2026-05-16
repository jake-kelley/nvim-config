-- Claude Code IDE bridge for Neovim. Implements the WebSocket MCP protocol
-- that Anthropic's VS Code / JetBrains extensions use, so the Claude CLI in
-- the bottom-left pane sees the file under the cursor, visual selections,
-- and LSP diagnostics in real time.
--
-- Wiring against our custom layout (lua/config/layout.lua):
--   - lazy = false so the WebSocket server is listening BEFORE the VimEnter
--     callback spawns `:terminal claude`. If the server isn't up at that
--     moment, the CLI won't auto-connect via env-var / lock-file discovery.
--   - terminal.provider = "none" tells claudecode.nvim not to launch its own
--     Claude split -- layout.lua already owns that pane.
--   - Keymaps that would launch a separate Claude terminal (<leader>ac,
--     <leader>af, <leader>am, <leader>ar, <leader>aC) are intentionally
--     skipped; only context-pushing and diff-handling keys are kept.

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false,
  opts = {
    auto_start      = true,
    track_selection = true,
    terminal = {
      provider = "none",
    },
  },
  keys = {
    { "<leader>a",  nil,                              desc = "AI/Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v", desc = "Send selection to Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer to Claude" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept Claude diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny Claude diff" },
  },
}
