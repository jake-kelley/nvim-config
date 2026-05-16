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

Install these **before** cloning the config:

| Tool | Why | Check it works |
|------|-----|----------------|
| [Neovim](https://neovim.io/) **≥ 0.10** | Editor itself | `nvim --version` |
| [Git](https://git-scm.com/) | LazyVim clones plugin repos | `git --version` |
| [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) (`pwsh`) — *Windows only* | Right-hand terminal pane | `pwsh -v` |
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude`) | Left bottom pane + IDE bridge | `claude --version` |
| A [Nerd Font](https://www.nerdfonts.com/) | Tree icons + task-checkbox glyphs | configure your terminal to use it |
| `node` (only if Claude was installed via npm) | Required by Claude CLI | `node --version` |

All of the above must be on `$PATH` / `$env:PATH`. Open a fresh terminal after installing each one.

## Deploy — Windows

1. **Back up any existing config** (skip if `$env:LOCALAPPDATA\nvim` doesn't exist yet):
   ```powershell
   $ts = Get-Date -Format "yyyyMMdd-HHmmss"
   Move-Item "$env:LOCALAPPDATA\nvim"      "$env:LOCALAPPDATA\nvim.bak-$ts"      -ErrorAction SilentlyContinue
   Move-Item "$env:LOCALAPPDATA\nvim-data" "$env:LOCALAPPDATA\nvim-data.bak-$ts" -ErrorAction SilentlyContinue
   ```

2. **Clone the repo into the Neovim config location**:
   ```powershell
   git clone git@github.com:jake-kelley/nvim-config.git "$env:LOCALAPPDATA\nvim"
   ```
   *No SSH keys set up?* Use HTTPS instead: `https://github.com/jake-kelley/nvim-config.git`.

3. **Launch Neovim** — first start does a lot of work, just let it finish:
   ```powershell
   nvim
   ```
   On the first run, in order:
   - `lazy.nvim` is bootstrapped from GitHub.
   - All plugins listed in `lua/plugins/` are downloaded.
   - Mason installs LSP servers, formatters, and parsers (Treesitter).
   - The four-pane layout opens; Claude starts in the bottom-left pane and connects to the IDE bridge.

   Wait until the spinner stops and the Lazy UI closes (or press `q` to dismiss it). **Quit and relaunch once** to make sure everything boots cleanly with all plugins available.

4. **Verify**:
   - `:Lazy` → status should be all green ticks, no red/yellow.
   - `:checkhealth` → no errors from `lazy`, `claudecode`, `neo-tree`, `mason`, `treesitter`.
   - `:Mason` → required LSPs are installed.
   - In the Claude pane, you should see a small IDE-connected indicator (varies by Claude version) — confirms `coder/claudecode.nvim` is bridged.

5. **(Optional) Override the global Claude trust prompt** — if you want Claude to never ask "Do you trust the files in this folder?" again, add to `~\.claude\settings.json`:
   ```json
   { "permissions": { "defaultMode": "bypassPermissions" } }
   ```

## Deploy — Linux / macOS

The shell pane is hardcoded to `pwsh -NoLogo`, and the `:cd` sync sends a PowerShell `Set-Location` command. To use bash/zsh:

1. Edit `lua/config/layout.lua`:
   - In `start_shell_terminal()`, replace `"terminal pwsh -NoLogo"` with `"terminal"` (or `"terminal bash"`, etc.).
   - In the `DirChanged` autocmd, replace the `Set-Location -LiteralPath '...'` line with `cd '<escaped>'` (or your shell's equivalent).

2. Back up your existing config:
   ```bash
   mv ~/.config/nvim       ~/.config/nvim.bak.$(date +%s)        2>/dev/null
   mv ~/.local/share/nvim  ~/.local/share/nvim.bak.$(date +%s)   2>/dev/null
   ```

3. Clone and launch:
   ```bash
   git clone git@github.com:jake-kelley/nvim-config.git ~/.config/nvim
   nvim
   ```

4. Follow steps 3–4 from the Windows section (Lazy install, verify health).

## Updating

```bash
cd $LOCALAPPDATA/nvim     # PowerShell: cd $env:LOCALAPPDATA\nvim
git pull
nvim +"Lazy sync" +qa     # pull and sync plugin updates in one shot
```

## Uninstall / rollback

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data"
# Restore your backup if you have one:
Move-Item "$env:LOCALAPPDATA\nvim.bak-*"      "$env:LOCALAPPDATA\nvim"
Move-Item "$env:LOCALAPPDATA\nvim-data.bak-*" "$env:LOCALAPPDATA\nvim-data"
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
