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

The installer is idempotent — safe to re-run at any time. It skips anything already installed, self-updates from git, and logs everything to `~/.dotfiles/logs/`.

## What gets installed

| Category | Packages |
|----------|----------|
| Shell | zsh, oh-my-zsh, oh-my-posh, nerd font |
| Editor | neovim, lazy.nvim (auto-bootstraps) |
| Terminal | tmux, tpm, tmux-powerline, tmux-continuum |
| CLI tools | fzf, ripgrep, eza, bat, jq, gh, curl, pass, fd, zoxide, htop, tldr, httpie, glow, neofetch |
| Git tools | git-delta (syntax-highlighted diffs), lazygit (terminal UI) |
| System | dust (disk usage), duf (disk free), procs (process viewer) |
| DevOps | lazydocker, yq (YAML processor) |
| Languages | pyenv, python 3.x, pip, virtualenv, node, npm |
| Containers | docker, kubectl |
| Security | gnupg, pinentry, pass (password store) |
| Clipboard | reattach-to-user-namespace (mac), xclip (linux) |

## Structure

```
~/.dotfiles/
├── install.sh
├── shell/
│   ├── .profile           # login env — PATH, brew, pyenv, go (shared)
│   ├── shrc               # interactive config — aliases, env vars, fzf (shared)
│   └── logout             # logout actions (shared)
├── zsh/
│   ├── .zshrc             # sources shrc + oh-my-zsh + oh-my-posh
│   ├── .zprofile          # sources .profile
│   └── .zlogout           # sources logout
├── bash/
│   ├── .bashrc            # sources shrc + oh-my-posh
│   ├── .bash_profile      # sources .profile + .bashrc
│   └── .bash_logout       # sources logout
├── tmux/
│   ├── .tmux.conf
│   └── powerline/         # config, segments, themes
├── nvim/                   # full neovim config
├── oh-my-posh/             # prompt theme + color palette
├── git/
│   └── .gitignore_global
├── gnupg/
│   └── gpg-agent.conf     # passphrase caching + pinentry
└── logs/                   # install logs (gitignored)
```

## Shell config architecture

```
Login (once per session):
  .profile              shared PATH, brew, pyenv, go
  .zprofile             sources .profile
  .bash_profile         sources .profile + .bashrc

Interactive (every shell):
  shell/shrc            shared aliases, EDITOR, fzf, eza, bat, zoxide, auto-tmux
  .zshrc                sources shrc + oh-my-zsh + oh-my-posh (zsh)
  .bashrc               sources shrc + oh-my-posh (bash)

Logout:
  shell/logout          shared cleanup
  .zlogout              sources logout
  .bash_logout          sources logout
```

One place for aliases and env vars. One place for PATH. Shell-specific stuff stays in its own file.

## Symlinks

| Source | Target |
|--------|--------|
| `shell/.profile` | `~/.profile` |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zprofile` | `~/.zprofile` |
| `zsh/.zlogout` | `~/.zlogout` |
| `bash/.bash_profile` | `~/.bash_profile` |
| `bash/.bashrc` | `~/.bashrc` |
| `bash/.bash_logout` | `~/.bash_logout` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `nvim/` | `~/.config/nvim` |
| `tmux/powerline/` | `~/.config/tmux-powerline` |
| `git/.gitignore_global` | `~/.gitignore_global` |

`oh-my-posh/` and `gnupg/` are referenced by path — no symlinks needed.

## Machine-specific config

Put local overrides in `~/.zshrc.local` or `~/.bashrc.local` (not tracked by git):

```bash
# Custom aliases, paths, secrets, tokens
export GITHUB_TOKEN="..."
alias k="kubectl"
```

## First-run setup

The installer prompts for:
- **Name and email** — used for git config, GPG key, and pass
- **GPG passphrase** — generates a 4096-bit RSA key for password encryption

This sets up `git`, `gpg`, and `pass` in one go. On re-run, existing config is detected and skipped.

## Tmux

Prefix is `Ctrl-s`. Key bindings:

| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + s` | fzf session switcher |
| `prefix + C` | New session (named after current dir) |
| `prefix + X` | Kill session (switches to next) |
| `prefix + g` | Scratch popup |
| `prefix + r` | Reload config |
| `prefix + I` | Install plugins (TPM) |

Sessions auto-save every 15 minutes and auto-restore on tmux start via tmux-continuum.

## Aliases

Defined in `shell/shrc` (shared by zsh and bash):

| Alias | Command |
|-------|---------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza --icons --group-directories-first -la` |
| `la` | `eza --icons --group-directories-first -a` |
| `lt` | `eza --icons --group-directories-first --tree --level=2` |
| `claudex` | `claude --dangerously-skip-permissions` |
| `cd` | `zoxide` (auto-initialized, use `z` to jump by frecency) |

## Color theme

All colors come from the Nord palette defined in `oh-my-posh/theme.omp.json`. This single file is the source of truth for the zsh/bash prompt, tmux status bar, and tmux-powerline segments.
