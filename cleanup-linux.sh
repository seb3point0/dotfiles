#!/usr/bin/env bash
set -uo pipefail

# Cleanup script for Linux — removes previously hard-coded packages
# so the unified installer can re-install them cleanly via apt/brew.
#
# Usage: bash ~/.dotfiles/cleanup-linux.sh && ~/.dotfiles/install.sh

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This script is for Linux only." >&2
    exit 1
fi

info()    { printf '  \033[1;34m→\033[0m %s\n' "$*"; }
success() { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn()    { printf '  \033[1;33m!\033[0m %s\n' "$*"; }

# APT packages that were previously hard-coded
APT_PACKAGES=(
    git curl unzip jq gh nodejs npm neovim tmux fzf ripgrep eza bat
    xclip pass gnupg htop fd-find zoxide tldr httpie neofetch
)

# Packages that were installed from GitHub releases (now handled by brew)
GITHUB_BINARIES=(
    lazygit lazydocker dust duf procs yq delta glow
)

echo
printf '\033[1m── Cleaning up apt packages ──\033[0m\n'
for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        info "Removing $pkg..."
        sudo apt-get remove -y "$pkg" && success "$pkg removed"
    fi
done

echo
printf '\033[1m── Cleaning up GitHub-installed binaries ──\033[0m\n'
for bin in "${GITHUB_BINARIES[@]}"; do
    if [[ -f "/usr/local/bin/$bin" ]]; then
        info "Removing /usr/local/bin/$bin..."
        sudo rm -f "/usr/local/bin/$bin" && success "$bin removed"
    fi
done

echo
printf '\033[1m── Cleaning up old pyenv (if installed via pyenv.run) ──\033[0m\n'
if [[ -d "$HOME/.pyenv" && ! -f "/home/linuxbrew/.linuxbrew/bin/pyenv" ]]; then
    info "Removing ~/.pyenv..."
    rm -rf "$HOME/.pyenv" && success "pyenv removed"
fi

echo
printf '\033[1m── Cleaning up kubectl apt repo ──\033[0m\n'
if [[ -f /etc/apt/sources.list.d/kubernetes.list ]]; then
    info "Removing kubernetes apt source..."
    sudo rm -f /etc/apt/sources.list.d/kubernetes.list
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    success "kubernetes apt source removed"
fi

echo
printf '\033[1m── Autoremoving unused dependencies ──\033[0m\n'
sudo apt-get autoremove -y

echo
printf '\033[1;32mDone.\033[0m Run ~/.dotfiles/install.sh to reinstall cleanly.\n'
echo
