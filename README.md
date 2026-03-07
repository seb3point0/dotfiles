# dotfiles

Personal dotfiles for macOS and Linux. Covers zsh, tmux, and Neovim.

## Install

One-liner (curl install):

```bash
curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/seb3point0/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer is idempotent — safe to re-run, skips anything already present.

### What gets installed

| Step | What |
|------|------|
| Homebrew | Package manager |
| Brew packages | git, neovim, tmux, zsh, fzf, bat, eza, ripgrep, node, gh, huggingface-cli, kubectl, pyenv |
| Python | Installs `pyenv`, Python `3.14.3`, and sets it as the global default |
| Tap packages | scw (Scaleway), supabase, stripe, speedtest |
| Claude Code | `npm install -g @anthropic-ai/claude-code` |
| OpenAI Codex CLI | `npm install -g @openai/codex` |
| OpenCode | `brew install opencode-ai/tap/opencode` |
| Oh My Zsh | Shell framework |
| Zsh plugins | zsh-autosuggestions, zsh-syntax-highlighting |
| Powerlevel10k | Prompt theme |
| Symlinks | `~/.zshrc`, `~/.p10k.zsh`, `~/.tmux.conf` → dotfiles repo |
| Neovim config | Symlinked `~/.config/nvim`, all plugins via lazy.nvim (headless sync) |
| TPM plugins | tmux-resurrect, tmux-continuum |
| Default shell | Sets zsh as the default shell via `chsh` |

### Post-install

- Install a [Nerd Font](https://www.nerdfonts.com/) and set it in your terminal — **MesloLGS NF** is recommended (ships with Powerlevel10k)
- Run `p10k configure` to customize the prompt
- Machine-specific config (env vars, secrets, paths) goes in `~/.zshrc.local` — not tracked by git

---

## Repository layout

```
.dotfiles/
├── install.sh          # Installer (also works as curl | bash bootstrap)
├── zsh/
│   ├── zshrc           # Shell config → ~/.zshrc
│   ├── zprofile        # Login shell config → ~/.zprofile
│   └── p10k.zsh        # Powerlevel10k config → ~/.p10k.zsh
├── tmux/
│   ├── tmux.conf       # Tmux config → ~/.tmux.conf
│   └── scripts/
│       ├── battery.sh    # Battery % for status bar
│       ├── load.sh       # CPU load for status bar
│       ├── tailscale.sh  # Tailscale status for status bar
│       └── uptime.sh     # System uptime for status bar
└── nvim/               # Full Neovim config → ~/.config/nvim
    ├── init.lua
    └── lua/
        ├── globals.lua        # Leader key, platform globals
        ├── options.lua        # Editor settings
        ├── mappings.lua       # Key mappings
        ├── plugin_specs.lua   # Plugin list (lazy.nvim)
        ├── colorschemes.lua   # Theme loader
        └── config/            # Per-plugin config files
```

---

## Updating

```bash
cd ~/.dotfiles && git pull
```

Symlinks mean config changes take effect immediately. Restart your shell or tmux to pick them up.

---

## Zsh

### Behaviour

- Auto-attaches to (or creates) a tmux session named `default` on terminal open
- SSH connections rename the tmux window to the target hostname
- `claude` command renames the tmux window while it runs, restores on exit
- Colorized man pages via `LESS_TERMCAP_*`
- fzf uses ripgrep — respects `.gitignore`, includes hidden files

### Aliases

| Alias | Expands to |
|-------|-----------|
| `ls` | `eza --icons` |
| `l` | `eza -1 --icons` |
| `ll` | `eza -lh --icons --git` |
| `la` | `eza -lah --icons --git` |
| `lt` | `eza --tree --icons` |
| `lta` | `eza --tree --icons -a` |
| `myip` | `curl -s ifconfig.me` |
| `dps` | `docker ps` |
| `dpsa` | `docker ps -a` |
| `dlogs` | `docker logs -f` |
| `dexec` | `docker exec -it` |

---

## Tmux

**Prefix:** `C-s`

### Sessions

| Key | Action |
|-----|--------|
| `prefix + s` | fzf popup — fuzzy search and switch sessions |
| `prefix + $` | Rename current session |
| `prefix + d` | Detach from session |

### Windows

| Key | Action |
|-----|--------|
| `S-Left` / `S-Right` | Previous / next window (no prefix needed) |
| `prefix + c` | New window |
| `prefix + ,` | Rename window |
| `prefix + &` | Kill window |

### Panes

| Key | Action |
|-----|--------|
| `prefix + \|` | Split right (opens at current path) |
| `prefix + -` | Split down (opens at current path) |
| `prefix + h/j/k/l` | Navigate panes (vim-style) |
| `C-h/j/k/l` | Navigate panes, vim-aware — passes through inside Neovim (no prefix) |
| `M-←/→/↑/↓` | Navigate panes with Alt+arrow (no prefix) |
| `prefix + D` | Resize pane down 8 rows |
| `prefix + U` | Resize pane up 4 rows |
| `prefix + z` | Zoom / unzoom pane |
| `prefix + a` | Toggle pane synchronization |

### Utilities

| Key | Action |
|-----|--------|
| `prefix + g` | Scratch terminal popup at current path (80% size) |
| `prefix + r` | Reload tmux config |
| `prefix + e` | Edit `tmux.conf` in Neovim, reloads on save |
| `prefix + m` | Toggle mouse mode |
| `prefix + y` | Clear screen and scrollback history |
| `prefix + /` | Enter copy mode and search |

### Copy mode

Enter with `prefix + [`, exit with `q`.

| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `V` | Select entire line |
| `r` | Toggle rectangle selection |
| `y` | Yank selection to system clipboard |

### Session persistence (tmux-resurrect / tmux-continuum)

| Key | Action |
|-----|--------|
| `prefix + C-s` | Save session manually |
| `prefix + C-r` | Restore session manually |

Sessions auto-save every 15 minutes and auto-restore when tmux starts.

---

## Neovim

**Leader:** `,`  |  ~96 plugins via [lazy.nvim](https://github.com/folke/lazy.nvim)  |  Run `:Lazy` to manage plugins.

The config is based on [jdhao/nvim-config](https://github.com/jdhao/nvim-config).

### File & buffer

| Key | Action |
|-----|--------|
| `,w` | Save buffer |
| `,q` | Quit window |
| `,Q` | Force-quit all windows |
| `\d` | Delete current buffer, keep window |
| `\D` | Delete all other buffers |
| `\x` | Close quickfix and location list |
| `,ev` | Open `init.lua` in a new tab |
| `,sv` | Reload `init.lua` |
| `,cd` | Change cwd to the current file's directory |

### Navigation

| Key | Action |
|-----|--------|
| `;` | `:` — enter command mode without Shift |
| `H` | Jump to start of line |
| `L` | Jump to end of line (excludes trailing whitespace) |
| `f` | hop.nvim — jump to any visible character |
| `←/→/↑/↓` | Switch between splits |
| `gb` | Go to next buffer (or `{count}gb`) |
| `gB` | Go to previous buffer |
| `gx` | Open URL under cursor in browser |

### Editing

| Key | Action |
|-----|--------|
| `,p` / `,P` | Paste non-linewise text below / above current line |
| `,v` | Reselect the last pasted area |
| `,y` | Yank entire buffer |
| `,<space>` | Strip trailing whitespace |
| `J` / `gJ` | Join lines without moving the cursor |
| `A-j` / `A-k` | Move current line or selection down / up |
| `c` / `C` / `cc` | Change without polluting the default register |
| `Q` | Record macro (`q` is disabled and shows a reminder) |
| `Esc` | Close floating window |

### Insert mode

| Key | Action |
|-----|--------|
| `C-u` | Uppercase the word under cursor |
| `C-t` | Title-case the word under cursor |
| `C-a` | Jump to start of line |
| `C-e` | Jump to end of line |
| `C-d` | Delete character to the right |
| `A-;` | Append `;` at end of line and return to cursor position |

### Search

| Key | Action |
|-----|--------|
| `*` / `#` | Search word under cursor — shows match index via hlslens |
| `n` / `N` | Next / previous match with match count overlay |

### Code

| Key | Action |
|-----|--------|
| `gc` | Toggle comment — works in normal and visual mode |
| `Space + t` | Vista — tag / symbol browser |
| `Space + s` | nvim-tree — file explorer |
| `F11` | Toggle spell check |
| `,cl` | Toggle cursor column highlight |
| `,cb` | Blink cursor to locate it on screen |

### Text objects

| Key | Action |
|-----|--------|
| `iu` | URL text object (use with `d`, `y`, `c`, etc.) |
| `iB` | Entire buffer text object |

### Notable plugins

| Plugin | What it does |
|--------|-------------|
| nvim-lspconfig | LSP client — go-to-def, hover, diagnostics |
| nvim-cmp | Autocompletion with LSP, snippets, buffer, path sources |
| nvim-treesitter | Syntax highlighting and text objects |
| fzf-lua | Fuzzy finder — files, grep, buffers, LSP symbols |
| telescope.nvim | Alternative fuzzy picker |
| lualine | Status line |
| bufferline | Buffer/tab line at the top |
| gitsigns | Git change indicators in the gutter |
| vim-fugitive | `:Git` — full git workflow inside Neovim |
| neogit | Git UI (like Magit) |
| diffview.nvim | Side-by-side diff viewer |
| git-conflict.nvim | Conflict markers and resolution UI |
| gitlinker | Generate shareable git permalinks |
| glance.nvim | Peek LSP definitions / references in a popup |
| which-key | Press `,` and pause to see all available bindings |
| snacks.nvim | Notifications, scratch buffers, utilities |
| fidget.nvim | LSP progress spinner in the corner |
| nvim-ufo | Code folding with preview |
| nvim-tree | File explorer sidebar |
| dropbar.nvim | Breadcrumb navigation bar |
| hop.nvim | EasyMotion-style jump to any character |
| UltiSnips | Snippet engine — trigger with `C-j` |
| yanky.nvim | Yank history ring — `:YankyRingHistory` |
| vim-sandwich | Surround text objects with `sa`, `sd`, `sr` |
| vim-matchup | Enhanced `%` matching |
| vim-illuminate | Highlight other occurrences of word under cursor |
| render-markdown | Rendered markdown preview in buffer |
| lazydev.nvim | Lua type annotations for Neovim API |

---

## Machine-local overrides

`~/.zshrc.local` is sourced at the end of `.zshrc` and is not tracked by git. Use it for anything specific to one machine:

```bash
# Example ~/.zshrc.local
export AWS_PROFILE=prod
export PATH="$HOME/.cargo/bin:$PATH"
alias work="cd ~/code/my-project"
```
