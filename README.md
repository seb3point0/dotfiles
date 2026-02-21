# dotfiles

Personal shell, editor, and terminal configuration. Works on macOS and Linux via Homebrew.

## What's included

- **zsh** — Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting
- **tmux** — Gruvbox-styled status bar, vim-aware pane switching, sensible bindings
- **nvim** — [jdhao/nvim-config](https://github.com/jdhao/nvim-config) with Lazy.nvim, LSP, Treesitter, fzf-lua, and more

## Install

```bash
git clone https://github.com/seb3point0/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## What the installer does

1. Installs Homebrew (if missing)
2. Installs packages via brew: git, neovim, tmux, zsh, fzf, bat, ripgrep, node, gh
3. Installs Oh My Zsh, Powerlevel10k, zsh plugins
4. Symlinks configs to home directory
5. Sets up nvim config + runs headless plugin install
6. Sets zsh as default shell

## Symlinks

| Source | Target |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/p10k.zsh` | `~/.p10k.zsh` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `nvim/` | `~/.config/nvim` |

## Machine-specific config

Put machine-specific paths, env vars, and secrets in `~/.zshrc.local` — it's sourced at the end of `.zshrc` and is not tracked by git.

## Updating

```bash
cd ~/dotfiles
git pull
```

Symlinks mean changes take effect immediately (restart shell/tmux to pick them up).

## Fonts

Install a [Nerd Font](https://www.nerdfonts.com/) for proper icon/powerline support. Recommended: **MesloLGS NF** (ships with Powerlevel10k).
