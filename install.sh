#!/usr/bin/env bash
set -uo pipefail

# ============================================================================
# dotfiles installer
# Works on macOS (Homebrew) and Linux/Ubuntu (apt).
# Safe to re-run — skips anything already present.
#
# Fresh install:  curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/install.sh | bash
# From repo:      ~/.dotfiles/install.sh
# ============================================================================

DOTFILES_REPO="https://github.com/seb3point0/dotfiles.git"
OS="$(uname -s)"
ERRORS=()
LOG_FILE=""

# ─── Packages ─────────────────────────────────────────────────────────────
# Edit these lists to add/remove packages. The installer handles the rest.

BREW_PACKAGES=(git curl jq gh node npm nvim tmux fzf ripgrep eza bat pyenv kubectl pass)
BREW_CASKS=(font-meslo-lg-nerd-font)
BREW_TAPS=(jandedobbeleer/oh-my-posh)
BREW_TAP_PACKAGES=(jandedobbeleer/oh-my-posh/oh-my-posh)

APT_PACKAGES=(git curl unzip jq gh nodejs npm neovim tmux fzf ripgrep eza bat xclip pass gnupg)

ZSH_PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
)

PYENV_BUILD_DEPS=(make build-essential libssl-dev zlib1g-dev libbz2-dev
    libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev xz-utils
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev)

PIP_PACKAGES=(virtualenv)

SYMLINKS=(
    "shell/.profile|.profile"
    "zsh/.zshrc|.zshrc"
    "zsh/.zprofile|.zprofile"
    "bash/.bash_profile|.bash_profile"
    "bash/.bashrc|.bashrc"
    "zsh/.zlogout|.zlogout"
    "bash/.bash_logout|.bash_logout"
    "tmux/.tmux.conf|.tmux.conf"
    "nvim|.config/nvim"
    "tmux/powerline|.config/tmux-powerline"
    "git/.gitignore_global|.gitignore_global"
)

# ─── Helpers ───────────────────────────────────────────────────────────────

setup_logging() {
    local log_dir="$HOME/.dotfiles/logs"
    mkdir -p "$log_dir"
    LOG_FILE="$log_dir/install-$(date +%Y%m%d-%H%M%S).log"
    : > "$LOG_FILE"
    # Clean up logs older than 30 days
    find "$log_dir" -name "install-*.log" -mtime +30 -delete 2>/dev/null || true
}

log()     { [[ -n "$LOG_FILE" ]] && printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >> "$LOG_FILE"; }
info()    { printf '  \033[1;34m→\033[0m %s\n' "$*"; log "INFO  $*"; }
success() { printf '  \033[1;32m✓\033[0m %s\n' "$*"; log "OK    $*"; }
warn()    { printf '  \033[1;33m!\033[0m %s\n' "$*" >&2; log "WARN  $*"; }
section() { printf '\n\033[1m── %s ──\033[0m\n' "$*"; log "===== $* ====="; }

has() { command -v "$1" &>/dev/null; }

# Run a command, logging full output. Only show our own messages to the user.
run_quiet() {
    local label="$1"; shift
    log "RUN   $label: $*"
    if "$@" >> "$LOG_FILE" 2>&1; then
        log "OK    $label"
        return 0
    else
        log "FAIL  $label (exit $?)"
        return 1
    fi
}

# Run a piped install (curl | bash), logging output.
run_piped() {
    local label="$1" url="$2"; shift 2
    log "RUN   $label: curl $url | bash $*"
    if curl -fsSL "$url" | bash "$@" >> "$LOG_FILE" 2>&1; then
        log "OK    $label"
        return 0
    else
        log "FAIL  $label (exit $?)"
        return 1
    fi
}

# User identity — collected once, used by git + gpg + pass
USER_FULLNAME=""
USER_EMAIL=""
GPG_PASSPHRASE=""

try() {
    if ! "$@"; then
        ERRORS+=("$*")
        warn "Failed: $*"
        return 1
    fi
}

# ─── Bootstrap ─────────────────────────────────────────────────────────────
# When piped via curl, clone the repo first then re-exec from disk.

bootstrap() {
    if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
        DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        return
    fi

    local dotfiles="$HOME/.dotfiles"

    if ! has git; then
        if [[ "$OS" == "Darwin" ]]; then
            xcode-select --install 2>/dev/null || true
        else
            sudo apt-get update -y && sudo apt-get install -y git
        fi
    fi

    if [[ -d "$dotfiles/.git" ]]; then
        info "Dotfiles repo exists — pulling latest..."
        git -C "$dotfiles" pull --ff-only
    else
        info "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$dotfiles"
    fi

    exec bash "$dotfiles/install.sh" "$@"
}

# ─── Self-update ───────────────────────────────────────────────────────────

self_update() {
    [[ -d "$DOTFILES/.git" ]] || return 0
    git -C "$DOTFILES" remote get-url origin &>/dev/null || return 0

    info "Checking for dotfiles updates..."
    if ! git -C "$DOTFILES" fetch --quiet origin main 2>/dev/null; then
        warn "Could not reach remote — running with local version"
        return 0
    fi

    local local_sha remote_sha
    local_sha="$(git -C "$DOTFILES" rev-parse HEAD)"
    remote_sha="$(git -C "$DOTFILES" rev-parse origin/main 2>/dev/null || echo "$local_sha")"

    if [[ "$local_sha" != "$remote_sha" ]]; then
        info "Pulling latest dotfiles..."
        git -C "$DOTFILES" pull --ff-only --quiet
        info "Updated — re-running installer"
        exec bash "$DOTFILES/install.sh" "$@"
    fi

    info "Dotfiles up to date"
}

# ─── Package manager ──────────────────────────────────────────────────────

setup_package_manager() {
    section "Package manager"
    if [[ "$OS" == "Darwin" ]]; then
        if has brew; then
            info "Homebrew already installed"
            info "Updating Homebrew..."
            try brew update && success "Homebrew updated"
            info "Upgrading packages..."
            try brew upgrade && success "Packages upgraded"
        else
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
            success "Homebrew installed"
        fi
    else
        info "Updating apt..."
        sudo apt-get update -y
        info "Upgrading packages..."
        sudo apt-get upgrade -y || warn "Some packages failed to upgrade"
        success "System packages up to date"
    fi
}

# ─── CLI tools ─────────────────────────────────────────────────────────────

setup_cli_tools() {
    section "CLI tools"
    if [[ "$OS" == "Darwin" ]]; then
        local pkg
        for pkg in "${BREW_PACKAGES[@]}"; do
            if has "$pkg"; then
                info "$pkg already installed"
            else
                info "Installing $pkg..."
                try brew install "$pkg" && success "$pkg installed"
            fi
        done

        # Taps + tap packages
        local tap
        for tap in "${BREW_TAPS[@]}"; do
            brew tap "$tap" 2>/dev/null || true
        done
        for pkg in "${BREW_TAP_PACKAGES[@]}"; do
            local bin="${pkg##*/}"
            if has "$bin"; then
                info "$bin already installed"
            else
                info "Installing $bin..."
                try brew install "$pkg" && success "$bin installed"
            fi
        done

        # Casks
        local cask
        for cask in "${BREW_CASKS[@]}"; do
            if brew list --cask "$cask" &>/dev/null; then
                info "$cask already installed"
            else
                info "Installing $cask..."
                try brew install --cask "$cask" && success "$cask installed"
            fi
        done

        # Docker Desktop (check binary, not just cask — may be installed outside brew)
        if ! has docker; then
            info "Installing Docker Desktop..."
            try brew install --cask docker && success "Docker Desktop installed"
        else
            info "Docker already installed"
        fi

        # tmux-yank clipboard support
        if has reattach-to-user-namespace; then
            info "reattach-to-user-namespace already installed"
        else
            info "Installing reattach-to-user-namespace..."
            try brew install reattach-to-user-namespace && success "reattach-to-user-namespace installed"
        fi
    else
        # Ubuntu / Debian
        local pkg
        for pkg in "${APT_PACKAGES[@]}"; do
            if dpkg -s "$pkg" &>/dev/null; then
                info "$pkg already installed"
            else
                info "Installing $pkg..."
                try sudo apt-get install -y "$pkg" && success "$pkg installed"
            fi
        done

        # oh-my-posh (no apt package)
        if has oh-my-posh || [[ -x "$HOME/.local/bin/oh-my-posh" ]]; then
            info "oh-my-posh already installed"
        else
            info "Installing oh-my-posh..."
            mkdir -p "$HOME/.local/bin"
            if run_piped "oh-my-posh" "https://ohmyposh.dev/install.sh" -s -- -d "$HOME/.local/bin"; then
                # Ensure it's on PATH for the rest of this script
                export PATH="$HOME/.local/bin:$PATH"
                success "oh-my-posh installed"
            else
                ERRORS+=("oh-my-posh install")
                warn "Failed: oh-my-posh install — see $LOG_FILE"
            fi
        fi

        # Nerd Font (no apt package)
        local font_dir="$HOME/.local/share/fonts"
        if ls "$font_dir"/Meslo* &>/dev/null 2>&1; then
            info "Meslo Nerd Font already installed"
        else
            info "Installing Meslo Nerd Font..."
            mkdir -p "$font_dir"
            if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz" | tar -xJ -C "$font_dir"; then
                fc-cache -f "$font_dir"
                success "Meslo Nerd Font installed"
            else
                ERRORS+=("Meslo Nerd Font install")
                warn "Failed: Nerd Font download — install manually"
            fi
        fi

        # kubectl (needs its own repo)
        if ! has kubectl; then
            info "Installing kubectl..."
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
            echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
            sudo apt-get update -y
            try sudo apt-get install -y kubectl && success "kubectl installed"
        else
            info "kubectl already installed"
        fi

        # Docker
        if ! has docker; then
            info "Installing Docker..."
            if curl -fsSL https://get.docker.com | sh; then
                sudo usermod -aG docker "$USER" 2>/dev/null || true
                success "Docker installed (log out and back in for group change)"
            else
                ERRORS+=("Docker install")
                warn "Failed: Docker install — install manually"
            fi
        else
            info "Docker already installed"
        fi
    fi
}

# ─── Zsh ───────────────────────────────────────────────────────────────────

setup_zsh() {
    section "Zsh"

    if ! has zsh; then
        if [[ "$OS" == "Darwin" ]]; then
            try brew install zsh
        else
            try sudo apt-get install -y zsh
        fi
    else
        info "zsh already installed"
    fi

    # Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh..."
        if run_piped "Oh My Zsh" "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" -s -- --unattended; then
            success "Oh My Zsh installed"
        else
            ERRORS+=("Oh My Zsh install")
            warn "Failed: Oh My Zsh install — see $LOG_FILE"
        fi
    fi

    # Plugins
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local entry name url
    for entry in "${ZSH_PLUGINS[@]}"; do
        name="${entry%%|*}"
        url="${entry##*|}"
        if [[ -d "$custom/plugins/$name" ]]; then
            info "$name already installed"
        else
            info "Installing $name..."
            try git clone --depth=1 "$url" "$custom/plugins/$name" && success "$name installed"
        fi
    done

    # Default shell
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$SHELL" != *zsh* ]]; then
        info "Setting zsh as default shell..."
        if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        try chsh -s "$zsh_path" && success "Default shell set to zsh"
    else
        info "zsh is already the default shell"
    fi
}

# ─── Tmux ──────────────────────────────────────────────────────────────────

setup_tmux() {
    section "Tmux"

    # TPM
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        info "TPM already installed"
    else
        info "Installing TPM..."
        try git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        success "TPM installed"
    fi
}

# ─── Python ────────────────────────────────────────────────────────────────

setup_python() {
    section "Python"

    # Build deps (Linux)
    if [[ "$OS" == "Linux" ]]; then
        info "Installing pyenv build dependencies..."
        sudo apt-get install -y "${PYENV_BUILD_DEPS[@]}" 2>/dev/null || warn "Some build deps failed"
    fi

    # pyenv
    if ! has pyenv; then
        if [[ "$OS" == "Darwin" ]]; then
            try brew install pyenv
        else
            info "Installing pyenv..."
            run_piped "pyenv" "https://pyenv.run"
            if [[ -d "$HOME/.pyenv/bin" ]]; then
                success "pyenv installed"
            else
                ERRORS+=("pyenv install")
                warn "Failed: pyenv install — see $LOG_FILE"
            fi
        fi
    else
        info "pyenv already installed"
    fi

    # Initialize for this script
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

    if ! has pyenv; then
        warn "pyenv not available — skipping Python install"
        return 0
    fi

    # Latest stable Python 3
    local latest
    latest="$(pyenv install --list 2>/dev/null | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')"
    if [[ -z "$latest" ]]; then
        warn "Could not determine latest Python version"
        return 0
    fi

    if pyenv versions --bare | grep -qF "$latest"; then
        info "Python $latest already installed"
    else
        info "Installing Python $latest (this takes a few minutes)..."
        try pyenv install "$latest" && success "Python $latest installed"
    fi
    pyenv global "$latest"

    # pip packages
    info "Upgrading pip..."
    pip install --upgrade pip 2>/dev/null || true
    local pkg
    for pkg in "${PIP_PACKAGES[@]}"; do
        if pip show "$pkg" &>/dev/null; then
            info "$pkg already installed"
        else
            info "Installing $pkg..."
            try pip install "$pkg" && success "$pkg installed"
        fi
    done
}

# ─── Identity ─────────────────────────────────────────────────────────────
# Collect name, email, and GPG passphrase once. Used by git, gpg, and pass.

collect_identity() {
    section "Identity"

    # Try to pull existing values
    USER_FULLNAME="$(git config --global --get user.name 2>/dev/null || true)"
    USER_EMAIL="$(git config --global --get user.email 2>/dev/null || true)"

    if [[ -n "$USER_FULLNAME" && -n "$USER_EMAIL" ]]; then
        info "Identity: $USER_FULLNAME <$USER_EMAIL>"
    elif [[ -r /dev/tty ]]; then
        if [[ -z "$USER_FULLNAME" ]]; then
            read -r -p "  Full name: " USER_FULLNAME < /dev/tty
        fi
        if [[ -z "$USER_EMAIL" ]]; then
            read -r -p "  Email: " USER_EMAIL < /dev/tty
        fi
    else
        warn "No identity set and no terminal available — skipping"
        return
    fi

    # Ask for GPG passphrase if we'll need to create a key
    if [[ -z "$GPG_PASSPHRASE" && -n "$USER_EMAIL" && -r /dev/tty ]]; then
        local existing_key
        existing_key="$(gpg --list-secret-keys --keyid-format LONG "$USER_EMAIL" 2>/dev/null || true)"
        if [[ -z "$existing_key" ]]; then
            info "No GPG key found for $USER_EMAIL — will create one"
            local confirm=""
            while true; do
                read -r -s -p "  GPG passphrase (for new key): " GPG_PASSPHRASE < /dev/tty
                echo
                read -r -s -p "  Confirm passphrase: " confirm < /dev/tty
                echo
                if [[ -z "$GPG_PASSPHRASE" ]]; then
                    warn "Empty passphrase — GPG key will not be created"
                    break
                elif [[ "$GPG_PASSPHRASE" == "$confirm" ]]; then
                    success "Passphrase confirmed"
                    break
                else
                    warn "Passphrases do not match — try again"
                    GPG_PASSPHRASE=""
                fi
            done
        fi
    fi
}

# ─── Git identity ─────────────────────────────────────────────────────────

setup_git_identity() {
    section "Git identity"

    if [[ -z "$USER_FULLNAME" || -z "$USER_EMAIL" ]]; then
        warn "No identity collected — skipping git config"
        return
    fi

    git config --global user.name "$USER_FULLNAME"
    git config --global user.email "$USER_EMAIL"
    info "Git identity: $USER_FULLNAME <$USER_EMAIL>"

    # Global gitignore
    git config --global core.excludesFile "$HOME/.gitignore_global"
    info "Global gitignore set"
}

# ─── GPG ───────────────────────────────────────────────────────────────────

setup_gpg() {
    section "GPG"
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    # Install pinentry per platform
    local pinentry=""
    if [[ "$OS" == "Darwin" ]]; then
        if has pinentry-mac; then
            info "pinentry-mac already installed"
        else
            info "Installing pinentry-mac..."
            try brew install pinentry-mac
        fi
        pinentry="$(command -v pinentry-mac 2>/dev/null || echo "/opt/homebrew/bin/pinentry-mac")"
    else
        if has pinentry-curses; then
            pinentry="$(command -v pinentry-curses)"
        fi
    fi

    # Generate gpg-agent.conf from dotfiles base + platform pinentry
    local conf="$HOME/.gnupg/gpg-agent.conf"
    cp "$DOTFILES/gnupg/gpg-agent.conf" "$conf"
    if [[ -n "$pinentry" ]]; then
        echo "pinentry-program $pinentry" >> "$conf"
        success "Pinentry: $pinentry"
    fi
    chmod 600 "$conf"

    # Restart agent to pick up changes
    gpgconf --kill gpg-agent 2>/dev/null || true

    # Generate GPG key if none exists for this email
    if [[ -n "$USER_EMAIL" ]]; then
        local existing_key
        existing_key="$(gpg --list-secret-keys --keyid-format LONG "$USER_EMAIL" 2>/dev/null || true)"
        if [[ -n "$existing_key" ]]; then
            info "GPG key already exists for $USER_EMAIL"
        elif [[ -n "$GPG_PASSPHRASE" ]]; then
            info "Generating GPG key for $USER_FULLNAME <$USER_EMAIL>..."
            if gpg --batch --gen-key <<GPGEOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $USER_FULLNAME
Name-Email: $USER_EMAIL
Expire-Date: 0
Passphrase: $GPG_PASSPHRASE
%commit
GPGEOF
            then
                success "GPG key generated"
            else
                ERRORS+=("GPG key generation")
                warn "Failed: GPG key generation"
            fi
        else
            info "No passphrase provided — skipping GPG key generation"
        fi
    fi

    # Clear passphrase from memory
    GPG_PASSPHRASE=""

    info "GPG configured"
}

# ─── Pass ──────────────────────────────────────────────────────────────────

setup_pass() {
    section "Password store"

    if [[ -z "$USER_EMAIL" ]]; then
        warn "No email set — skipping pass init"
        return
    fi

    if ! has pass; then
        warn "pass not installed — skipping"
        return
    fi

    # Check if pass is already initialized
    if [[ -d "$HOME/.password-store" ]]; then
        info "Password store already initialized"
        return
    fi

    # Check if GPG key exists for this email
    local key_id
    key_id="$(gpg --list-secret-keys --keyid-format LONG "$USER_EMAIL" 2>/dev/null | grep -m1 'sec' | awk '{print $2}' | cut -d'/' -f2 || true)"

    if [[ -z "$key_id" ]]; then
        warn "No GPG key found for $USER_EMAIL — cannot initialize pass"
        return
    fi

    info "Initializing password store with key $key_id..."
    try pass init "$key_id" && success "Password store initialized"
}

# ─── Symlinks ─────────────────────────────────────────────────────────────

setup_symlinks() {
    section "Symlinks"
    mkdir -p "$HOME/.config"

    local entry src dst
    for entry in "${SYMLINKS[@]}"; do
        src="$DOTFILES/${entry%%|*}"
        dst="$HOME/${entry##*|}"

        # Ensure parent dir exists
        mkdir -p "$(dirname "$dst")"

        if [[ -L "$dst" ]]; then
            local current
            current="$(readlink "$dst")"
            if [[ "$current" == "$src" ]]; then
                info "$dst already linked"
                continue
            fi
            # Timestamped backup so repeated runs don't overwrite
            local bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
            warn "Backing up $dst → $bak"
            mv "$dst" "$bak"
        elif [[ -e "$dst" ]]; then
            local bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
            warn "Backing up $dst → $bak"
            mv "$dst" "$bak"
        fi
        ln -sf "$src" "$dst"
        success "$dst → $src"
    done

    # Machine-specific overrides
    for local_rc in .zshrc.local .bashrc.local; do
        if [[ ! -f "$HOME/$local_rc" ]]; then
            touch "$HOME/$local_rc"
            info "Created empty ~/$local_rc"
        fi
    done
}

# ─── Post-install ──────────────────────────────────────────────────────────

setup_post_install() {
    section "Post-install"

    # Install tmux plugins via TPM
    if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
        info "Installing tmux plugins..."
        try "$HOME/.tmux/plugins/tpm/bin/install_plugins" && success "Tmux plugins installed"
    fi

    # Install nvim plugins via lazy.nvim
    if has nvim; then
        info "Installing nvim plugins..."
        try nvim --headless "+Lazy! sync" +qa 2>/dev/null && success "Nvim plugins installed"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    bootstrap "$@"
    setup_logging

    printf '\033[1;36m'
    printf '  ┌──────────────────────────┐\n'
    printf '  │     dotfiles installer    │\n'
    printf '  └──────────────────────────┘\n'
    printf '\033[0m'
    printf '  OS: %s | Dotfiles: %s\n' "$OS" "$DOTFILES"
    log "OS: $OS | Dotfiles: $DOTFILES"

    self_update "$@"

    collect_identity
    setup_package_manager
    setup_zsh
    setup_symlinks
    # Source .profile so PATH is set for the rest of the install
    # (prevents warnings from oh-my-posh, pyenv about missing paths)
    [ -f "$HOME/.profile" ] && . "$HOME/.profile"
    setup_cli_tools
    setup_tmux
    setup_python
    setup_git_identity
    setup_gpg
    setup_pass
    setup_post_install

    # ── Summary ──
    echo
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        printf '  \033[1;33mDone with %d warning(s):\033[0m\n' "${#ERRORS[@]}"
        local err
        for err in "${ERRORS[@]}"; do
            printf '    \033[1;31m✗\033[0m %s\n' "$err"
        done
    else
        printf '  \033[1;32mDone — no errors.\033[0m\n'
    fi

    echo
    printf '  \033[1mNotes:\033[0m\n'
    printf '    Set your terminal font to a Nerd Font (e.g. MesloLGS NF)\n'
    printf '    Machine-specific config goes in ~/.zshrc.local or ~/.bashrc.local\n'
    printf '    Full log: %s\n' "$LOG_FILE"
    echo

    # Launch zsh so the user gets the configured prompt immediately
    if has zsh; then
        info "Launching zsh..."
        exec zsh -l
    fi
}

main "$@"
