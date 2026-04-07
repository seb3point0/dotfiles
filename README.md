# dotfiles

Personal dotfiles for macOS and Ubuntu. Nord-themed terminal setup with zsh, tmux, neovim, and oh-my-posh.

## Install

**Fresh machine** (clones repo + installs everything):

```bash
curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/install.sh | bash
```

**From repo** (re-run after pulling changes):

```bash
~/.dotfiles/install.sh
```

The installer is idempotent — safe to re-run at any time. It skips anything already installed and self-updates from git before running.

## What gets installed

| Category | Packages |
|----------|----------|
| Shell | zsh, oh-my-zsh, oh-my-posh, nerd font |
| Editor | neovim, lazy.nvim (auto-bootstraps) |
| Terminal | tmux, tpm, tmux-powerline |
| CLI tools | fzf, ripgrep, eza, bat, jq, gh, curl |
| Languages | pyenv, python 3.x, pip, virtualenv, node, npm |
| Containers | docker, kubectl |
| Clipboard | reattach-to-user-namespace (mac), xclip (linux) |

## Structure

```
~/.dotfiles/
├── install.sh          # cross-platform installer
├── zsh/
│   ├── .zshrc          # portable base config
│   └── .zprofile       # login shell (brew, pyenv, paths)
├── tmux/
│   ├── .tmux.conf
│   └── powerline/      # config, segments, themes
├── nvim/               # full neovim config
└── oh-my-posh/         # prompt theme + color palette
```

## Symlinks

The installer creates these symlinks:

| Source | Target |
|--------|--------|
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zprofile` | `~/.zprofile` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `nvim/` | `~/.config/nvim` |
| `tmux/powerline/` | `~/.config/tmux-powerline` |

Everything else is referenced by path — no extra symlinks needed.

## Machine-specific config

Put local overrides in `~/.zshrc.local` (not tracked by git):

```bash
# Custom aliases, paths, secrets, tokens
export GITHUB_TOKEN="..."
alias k="kubectl"
```

## Color theme

All colors come from the Nord palette defined in `oh-my-posh/theme.omp.json`. This single file is the source of truth for zsh prompt, tmux status bar, and tmux-powerline segments.
