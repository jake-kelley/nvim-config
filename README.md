# nvim-config

Personal Neovim setup: LazyVim baseline + a custom four-pane IDE layout (file tree, editor, persistent task panel, dual-terminal row with Claude Code and PowerShell).

## Layout

```
┌─────────┬──────────────────────┬─────────────┐
│ file    │                      │  Tasks      │
│ tree    │       editor         │  (markdown, │
│ (toggle)│                      │   persists) │
├─────────┴──────────────────────┴─────────────┤
│   claude code        │   pwsh                │
└──────────────────────────────────────────────┘
```

- **Left:** `neo-tree` file tree, hidden by default, `<leader>e` to toggle. Width preserved across toggles (no width drift in the other panes).
- **Center:** editor area.
- **Right:** persistent task kanban backed by `~/.local/share/nvim/tasks.md` (Windows: `%LOCALAPPDATA%\nvim-data\tasks.md`). Auto-saves.
- **Bottom:** split row — Claude Code CLI on the left (with `--dangerously-skip-permissions`), PowerShell 7 on the right.

## Prerequisites

- **Neovim 0.10+**
- **Git**
- **PowerShell 7** (`pwsh`) on `$PATH` (Windows shell pane uses this)
- **Claude Code CLI** (`claude`) on `$PATH` for the Claude pane
- A Nerd Font for the file-tree icons and `render-markdown` checkboxes

## Install (Windows)

```powershell
# Back up any existing config first.
git clone git@github.com:jake-kelley/nvim-config.git $env:LOCALAPPDATA\nvim
nvim
```

LazyVim will bootstrap `lazy.nvim`, install all plugins (incl. the IDE bridge via `coder/claudecode.nvim`), and run Mason on first launch.

## Install (Linux / macOS)

The shell terminal in `lua/config/layout.lua` is hardcoded to `pwsh -NoLogo`, and the `:cd` sync sends `Set-Location` to that terminal. To use bash/zsh instead:

1. Edit `start_shell_terminal()` in `lua/config/layout.lua` — replace `"terminal pwsh -NoLogo"` with `"terminal"` (or your preferred shell command).
2. Edit the `DirChanged` autocmd in the same file — replace `Set-Location -LiteralPath '<path>'` with `cd '<path>'`.

Then:

```bash
git clone git@github.com:jake-kelley/nvim-config.git ~/.config/nvim
nvim
```

## Key bindings

### Layout / panes
| Key | Action |
|-----|--------|
| `<leader>e`  | Toggle file tree |
| `<leader>k`  | Toggle focus on task panel |
| `<leader>tc` | Focus Claude Code terminal |
| `<leader>ts` | Focus shell terminal |
| `<Esc><Esc>` | Exit terminal-insert mode |

### Tasks (buffer-local, inside the task panel only)
| Key | Action |
|-----|--------|
| `b` | Move task under cursor to Blocked |
| `d` | Move task under cursor to Done |
| `p` | Move task under cursor to In Progress |
| `n` | New task (prompt; inserted under Todo) |
| `x` | Delete task under cursor (confirms) |
| `r` | Rename task under cursor |

Same actions are also available globally as `<leader>td`, `<leader>tb`, `<leader>tp`, `<leader>tt`, `<leader>ta`.

### Claude IDE bridge (`coder/claudecode.nvim`)
| Key | Action |
|-----|--------|
| `<leader>as` (visual) | Send selection to Claude |
| `<leader>ab` | Add current buffer to Claude's context |
| `<leader>aa` | Accept Claude's proposed diff |
| `<leader>ad` | Deny Claude's proposed diff |

Editor activity (focused file, visual selections, LSP diagnostics) is mirrored to Claude automatically once the WebSocket bridge is up.

## File map

```
init.lua                       lazy.nvim bootstrap + LazyVim spec order
lua/config/layout.lua          The four-pane layout, snapshots, autocmds
lua/config/keymaps.lua         Global task / terminal keymaps
lua/plugins/lazyvim.lua        LazyVim baseline tweaks (snacks dashboard off)
lua/plugins/neo-tree.lua       File tree, with snapshot/restore on toggle
lua/plugins/render-markdown.lua Pretty task-panel rendering
lua/plugins/claudecode.lua     Claude Code IDE bridge wiring
lua/plugins/toggleterm.lua     Floating ad-hoc terminal (Ctrl-\)
lua/plugins/example.lua        LazyVim's example plugin overrides
```

## Notes on the layout's invariants

- `vim.opt.equalalways = false` (in `init.lua`) is load-bearing — without it, Vim re-equalizes window widths on every split open/close, which drifts the tasks panel away from its target width on neo-tree toggles.
- The neo-tree open/close handlers snapshot tasks/claude/shell widths *before* the toggle and restore them after, so the editor is the only window that flexes to absorb neo-tree's space.
- The Claude terminal is owned by `layout.lua`, not by `claudecode.nvim` (`terminal.provider = "none"`). The IDE bridge runs in parallel.
