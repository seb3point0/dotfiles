#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# dotfiles installer — works on macOS and Linux
# Installs brew, shell tooling, and symlinks configs.
# Safe to re-run: skips anything already present.
#
# Fresh install: curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/install.sh | bash
# ============================================================================

# If not running from a file (e.g. curl | bash), clone/pull the repo and re-exec
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    _dotfiles="$HOME/.dotfiles"
    _repo="https://github.com/seb3point0/dotfiles.git"
    if [[ -d "$_dotfiles/.git" ]]; then
        echo "Dotfiles already at $_dotfiles — pulling latest..."
        git -C "$_dotfiles" pull --ff-only
    else
        echo "Cloning dotfiles to $_dotfiles..."
        git clone "$_repo" "$_dotfiles"
    fi
    exec bash "$_dotfiles/install.sh" "$@"
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[dotfiles]${NC} $*"; }
success() { echo -e "${GREEN}[dotfiles]${NC} $*"; }
warn()    { echo -e "${YELLOW}[dotfiles]${NC} $*"; }
fail()    { echo -e "${RED}[dotfiles]${NC} $*"; exit 1; }

OS="$(uname -s)"

# ============================================================================
# Homebrew
# ============================================================================

install_brew() {
    # Remove leftover tap directories from previous failed installs before brew update runs.
    # These cause `brew update --force` (called inside the Homebrew installer) to abort.
    local tap_roots=(
        "/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps"
        "/opt/homebrew/Library/Taps"
        "/usr/local/Homebrew/Library/Taps"
    )
    for tap_root in "${tap_roots[@]}"; do
        if [[ -d "$tap_root/scaleway" ]]; then
            warn "Removing broken scaleway tap directory: $tap_root/scaleway"
            rm -rf "$tap_root/scaleway"
        fi
    done

    if command -v brew &>/dev/null; then
        info "Homebrew already installed"
        return
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to current session
    if [[ "$OS" == "Darwin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    fi

    success "Homebrew installed"
}

# ============================================================================
# Brew packages
# ============================================================================

install_brew_packages() {
    info "Installing brew packages..."

    local packages=(
        git
        neovim
        tmux
        zsh
        fzf
        bat
        eza
        ripgrep
        node
        tree-sitter-cli
        gh
        kubectl
        scw
    )

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            info "  $pkg — already installed"
        else
            info "  $pkg — installing..."
            brew install "$pkg" || warn "  $pkg — install failed (non-fatal, install manually if needed)"
        fi
    done

    success "Brew packages installed"
}

# ============================================================================
# Tap packages (third-party brew taps)
# ============================================================================

install_tap_packages() {
    info "Installing tap packages..."

    # Format: "tap/formula" — brew installs the tap automatically
    # Note: scw is in homebrew-core, installed via install_brew_packages instead
    local tap_packages=(
        "supabase/tap/supabase"
    )

    for formula in "${tap_packages[@]}"; do
        local pkg="${formula##*/}"
        if brew list "$pkg" &>/dev/null; then
            info "  $pkg — already installed"
        else
            info "  $pkg — installing..."
            brew install "$formula" || warn "  $pkg — install failed (non-fatal, install manually if needed)"
        fi
    done

    success "Tap packages installed"
}

# ============================================================================
# Stripe CLI
# ============================================================================

install_stripe() {
    if command -v stripe &>/dev/null; then
        info "Stripe CLI already installed"
        return
    fi

    if [[ "$OS" == "Darwin" ]]; then
        info "Installing Stripe CLI via brew..."
        brew install stripe/stripe-cli/stripe || warn "Stripe CLI install failed (non-fatal, install manually if needed)"
    else
        info "Installing Stripe CLI via apt..."
        curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public \
            | gpg --dearmor \
            | sudo tee /usr/share/keyrings/stripe.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" \
            | sudo tee /etc/apt/sources.list.d/stripe.list >/dev/null
        sudo apt update -qq
        sudo apt install -y stripe || warn "Stripe CLI install failed (non-fatal, install manually if needed)"
    fi

    success "Stripe CLI installed"
}

# ============================================================================
# Claude Code (npm global)
# ============================================================================

install_claude_code() {
    if command -v claude &>/dev/null; then
        info "Claude Code already installed"
        return
    fi

    if ! command -v npm &>/dev/null; then
        warn "npm not found — skipping Claude Code install"
        return
    fi

    info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
}

# ============================================================================
# OpenAI Codex CLI (npm global)
# ============================================================================

install_codex() {
    if command -v codex &>/dev/null; then
        info "OpenAI Codex CLI already installed"
        return
    fi

    if ! command -v npm &>/dev/null; then
        warn "npm not found — skipping OpenAI Codex CLI install"
        return
    fi

    info "Installing OpenAI Codex CLI..."
    npm install -g @openai/codex
    success "OpenAI Codex CLI installed"
}

# ============================================================================
# OpenCode (Homebrew)
# ============================================================================

install_opencode() {
    if brew list --formula opencode &>/dev/null; then
        info "OpenCode already installed"
        return
    fi

    info "Installing OpenCode via brew..."
    if brew install opencode-ai/tap/opencode; then
        success "OpenCode installed"
    else
        warn "OpenCode install failed (non-fatal, install manually if needed)"
    fi
}

# ============================================================================
# Oh My Zsh
# ============================================================================

install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed"
        return
    fi

    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "Oh My Zsh installed"
}

# ============================================================================
# Zsh plugins
# ============================================================================

install_zsh_plugins() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "$custom/plugins/zsh-autosuggestions" ]]; then
        info "Installing zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    fi

    if [[ ! -d "$custom/plugins/zsh-syntax-highlighting" ]]; then
        info "Installing zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
    fi

    success "Zsh plugins installed"
}

# ============================================================================
# Powerlevel10k
# ============================================================================

install_powerlevel10k() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local p10k_dir="$custom/themes/powerlevel10k"

    if [[ -d "$p10k_dir" ]]; then
        info "Powerlevel10k already installed"
        return
    fi

    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    success "Powerlevel10k installed"
}

# ============================================================================
# Neovim config (jdhao/nvim-config)
# ============================================================================

setup_nvim() {
    local nvim_target="$HOME/.config/nvim"

    if [[ -L "$nvim_target" ]]; then
        local current_link
        current_link=$(readlink "$nvim_target")
        if [[ "$current_link" == "$DOTFILES_DIR/nvim" ]]; then
            info "nvim config already symlinked"
            return
        fi
        warn "nvim config symlink points elsewhere ($current_link) — replacing"
        rm "$nvim_target"
    elif [[ -d "$nvim_target" ]]; then
        warn "Backing up existing nvim config to $nvim_target.bak"
        mv "$nvim_target" "$nvim_target.bak"
    fi

    mkdir -p "$HOME/.config"
    ln -sf "$DOTFILES_DIR/nvim" "$nvim_target"
    success "nvim config symlinked"

    if command -v nvim &>/dev/null; then
        info "Installing nvim plugins (headless)..."
        nvim --headless -c "lua require('lazy').sync({wait=true})" -c "qa" || \
            warn "nvim plugin sync returned non-zero — check :Lazy in nvim for details"
        success "nvim plugins installed"

        if command -v tree-sitter &>/dev/null; then
            info "Pre-installing tree-sitter parsers..."
            nvim --headless -c "lua local ts = require('nvim-treesitter'); ts.install('all'):wait()" -c "qa" || \
                warn "tree-sitter parser install returned non-zero — check :TSInstall in nvim for details"
            success "tree-sitter parsers installed"
        else
            warn "tree-sitter CLI not found — skipping parser pre-install"
        fi
    fi
}

# ============================================================================
# Symlinks
# ============================================================================

symlink() {
    local src="$1" dst="$2"

    if [[ -L "$dst" ]]; then
        local current
        current=$(readlink "$dst")
        if [[ "$current" == "$src" ]]; then
            info "  $dst — already linked"
            return
        fi
        warn "  $dst — repointing (was $current)"
        rm "$dst"
    elif [[ -f "$dst" ]]; then
        warn "  $dst — backing up existing file to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -sf "$src" "$dst"
    success "  $dst -> $src"
}

setup_symlinks() {
    info "Creating symlinks..."
    symlink "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
    symlink "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Ensure machine-local zsh override file exists
    [[ -f "$HOME/.zshrc.local" ]] || touch "$HOME/.zshrc.local"
}

# ============================================================================
# Claude Code settings
# ============================================================================

install_claude_settings() {
    local src="$DOTFILES_DIR/claude/settings.json"
    local dst="$HOME/.claude/settings.json"

    mkdir -p "$HOME/.claude"

    if [[ ! -f "$dst" ]]; then
        info "Creating Claude Code settings..."
        cp "$src" "$dst"
        success "Claude Code settings created"
        return
    fi

    info "Merging Claude Code settings..."
    local tmp
    tmp=$(mktemp)
    # Deep merge: union allow arrays, merge env keys, overwrite scalar settings
    jq -s '
        .[0] as $existing |
        .[1] as $desired |
        $existing |
        .env = (($existing.env // {}) + ($desired.env // {})) |
        .teammateMode = $desired.teammateMode |
        .permissions.allow = (
            ($existing.permissions.allow // []) + ($desired.permissions.allow // []) | unique
        )
    ' "$dst" "$src" > "$tmp" && mv "$tmp" "$dst"
    success "Claude Code settings updated"
}

# ============================================================================
# Default shell
# ============================================================================

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ -z "$zsh_path" ]]; then
        warn "zsh not found — skipping shell change"
        return
    fi

    local current_shell
    if [[ "$OS" == "Darwin" ]]; then
        current_shell=$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')
    else
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
    fi

    if [[ "$current_shell" == *zsh* ]]; then
        info "zsh is already the default shell"
        return
    fi

    # Make sure our zsh is in /etc/shells
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        info "Adding $zsh_path to /etc/shells (needs sudo)..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    info "Changing default shell to zsh (needs password)..."
    chsh -s "$zsh_path"
    success "Default shell set to zsh — log out and back in to take effect"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}  dotfiles installer${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "  OS:       $OS"
    echo -e "  Dotfiles: $DOTFILES_DIR"
    echo

    install_brew
    install_brew_packages
    install_tap_packages
    install_stripe
    install_claude_code
    install_codex
    install_opencode
    install_claude_settings
    install_ohmyzsh
    install_zsh_plugins
    install_powerlevel10k
    setup_symlinks
    setup_nvim
    set_default_shell

    echo
    success "All done!"
    echo
    echo -e "${CYAN}Notes:${NC}"
    echo "  - Machine-specific config goes in ~/.zshrc.local"
    echo "  - Run 'p10k configure' to customize your prompt"
    echo "  - Open nvim and run :Lazy to check plugin status"
    echo "  - Install a Nerd Font for powerline/icon support"
    echo
}

main "$@"
