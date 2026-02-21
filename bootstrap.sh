#!/usr/bin/env bash
set -euo pipefail

# Bootstrap: curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/bootstrap.sh | bash

DOTFILES_DIR="$HOME/.dotfiles"
REPO="https://github.com/seb3point0/dotfiles.git"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "Dotfiles already installed at $DOTFILES_DIR — pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
else
    echo "Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO" "$DOTFILES_DIR"
fi

exec bash "$DOTFILES_DIR/install.sh"
