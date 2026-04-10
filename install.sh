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

# Unified package list. Each entry is one of:
#   name              — same name on brew and apt
#   name:apt=alt      — brew name is "name", apt name is "alt"
#   name:apt=_        — brew-only (no apt package, use brew on Linux too)
#   name:linux=_      — macOS-only (skip on Linux entirely)
#   name:mac=_        — Linux-only (skip on macOS entirely)
PACKAGES=(
    git
    curl
    jq
    "gh"
    "node:apt=nodejs"
    npm
    "nvim:apt=neovim"
    tmux
    fzf
    ripgrep
    eza
    bat
    "pyenv:apt=_"
    "kubectl:apt=_"
    pass
    htop
    "fd:apt=fd-find"
    zoxide
    tldr
    httpie
    neofetch
    "glow:apt=_"
    "lazygit:apt=_"
    "lazydocker:apt=_"
    "dust:apt=_"
    "duf:apt=_"
    "procs:apt=_"
    "yq:apt=_"
    "git-delta:apt=_"
    # Linux-only
    "unzip:mac=_"
    "xclip:mac=_"
    "gnupg:mac=_"
    # macOS-only
    "reattach-to-user-namespace:linux=_"
)

BREW_CASKS=(font-meslo-lg-nerd-font)
BREW_TAPS=(jandedobbeleer/oh-my-posh)
BREW_TAP_PACKAGES=(jandedobbeleer/oh-my-posh/oh-my-posh)

ZSH_PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
)

PYENV_BUILD_DEPS=(make build-essential libssl-dev zlib1g-dev libbz2-dev
    libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev xz-utils
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev)

PIP_PACKAGES=(virtualenv libtmux)

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

# ─── Sudo wrapper ──────────────────────────────────────────────────────────
# Prompt for the sudo password once, cache it in an unexported shell
# variable, and feed it via stdin to every subsequent sudo call using -S.
# This is deterministic across distros regardless of sudoers timestamp
# caching behavior, and doesn't require a backgrounded refresher.
#
# Security model:
#   - Password lives in a single non-exported shell variable. Not written
#     to disk, not in argv, not in the environment, not logged.
#   - `sudo -S -p ''` reads from stdin silently, so the password never
#     echoes to the terminal and no askpass helper is needed.
#   - Cleanup (EXIT/INT/TERM/HUP) clears the variable and runs `sudo -k`
#     so the cached timestamp is invalidated before the script hands off
#     to the user's login shell.
#   - Disables core dumps via `ulimit -c 0` to avoid leaking the variable
#     to a crash dump.
#   - `readonly` is intentionally NOT used — we need to clear it on exit.
#
# STDIN HAZARD — read this before adding new sudo calls:
#   The wrapper pipes the password into sudo's stdin. Two consequences:
#     1. Upstream pipes are hijacked: `foo | sudo bar` — bar does NOT
#        see foo's output. Use a here-string or `sudo sh -c '... "$1" ...' _ arg`.
#     2. If the *target* command itself reads stdin (e.g. tee, cat, read),
#        it may consume leftover password bytes from the pipe buffer when
#        the sudo cache is warm and sudo skips reading. Never run sudo on
#        a command that reads stdin through this wrapper.
#   The only stdin-reading sudo call in this script (echo | sudo tee) was
#   rewritten to `sudo sh -c 'printf ... >> FILE' _ "$arg"` in setup_zsh.
SUDO_PASSWORD=""

prime_sudo() {
    [[ $EUID -eq 0 ]] && return 0   # already root, nothing to do
    section "Sudo"
    info "This installer requires sudo access to install packages."
    ulimit -c 0 2>/dev/null || true   # no core dumps while pw is in memory

    printf '  \033[1;34m→\033[0m sudo password for %s: ' "$USER" > /dev/tty
    IFS= read -rs SUDO_PASSWORD < /dev/tty
    printf '\n' > /dev/tty

    if [[ -z "$SUDO_PASSWORD" ]]; then
        warn "Empty password — later sudo calls will prompt"
        return 1
    fi

    # Validate the password without caching globally — catches typos now.
    if ! printf '%s\n' "$SUDO_PASSWORD" | command sudo -S -p '' -v 2>/dev/null; then
        warn "Sudo authentication failed — later sudo calls will prompt"
        SUDO_PASSWORD=""
        return 1
    fi

    trap 'clear_sudo_password' EXIT
    trap 'clear_sudo_password; exit 130' INT
    trap 'clear_sudo_password; exit 143' TERM HUP
    success "Sudo authenticated"
}

clear_sudo_password() {
    SUDO_PASSWORD=""
    command sudo -k 2>/dev/null || true
}

# Transparent sudo override. When the cached password is set, feed it via
# stdin with -S so sudo never prompts. Otherwise fall through to real sudo
# (e.g. for root user, or if auth failed and we're in best-effort mode).
sudo() {
    if [[ -n "${SUDO_PASSWORD:-}" ]]; then
        printf '%s\n' "$SUDO_PASSWORD" | command sudo -S -p '' "$@"
    else
        command sudo "$@"
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

    log "Checking for dotfiles updates..."
    if ! git -C "$DOTFILES" fetch --quiet origin main 2>/dev/null; then
        log "Could not reach remote — running with local version"
        return 0
    fi

    local local_sha remote_sha
    local_sha="$(git -C "$DOTFILES" rev-parse HEAD)"
    remote_sha="$(git -C "$DOTFILES" rev-parse origin/main 2>/dev/null || echo "$local_sha")"

    if [[ "$local_sha" != "$remote_sha" ]]; then
        git -C "$DOTFILES" pull --ff-only --quiet
        log "Dotfiles updated — re-running installer"
        exec bash "$DOTFILES/install.sh" "$@"
    fi

    log "Dotfiles up to date"
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

        # Install Homebrew on Linux for packages not in apt
        # Source shellenv first so `has brew` works in fresh/non-login shells
        if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        if has brew; then
            info "Homebrew (Linux) already installed"
            try brew update && success "Homebrew updated"
        else
            info "Installing Homebrew (Linux)..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
            success "Homebrew (Linux) installed"
        fi
    fi
}

# ─── CLI tools ─────────────────────────────────────────────────────────────

setup_cli_tools() {
    section "CLI tools"

    # Parse unified PACKAGES list and install per-platform
    local entry brew_name apt_name skip
    for entry in "${PACKAGES[@]}"; do
        brew_name="${entry%%:*}"
        apt_name="$brew_name"
        skip=false

        # Parse modifiers (apt=, mac=, linux=)
        if [[ "$entry" == *":"* ]]; then
            local modifier="${entry#*:}"
            case "$modifier" in
                apt=_)    [[ "$OS" != "Darwin" ]] && apt_name="" ;;   # brew-only
                apt=*)    apt_name="${modifier#apt=}" ;;               # different apt name
                mac=_)    [[ "$OS" == "Darwin" ]] && skip=true ;;     # Linux-only
                linux=_)  [[ "$OS" != "Darwin" ]] && skip=true ;;     # macOS-only
            esac
        fi

        $skip && continue

        if [[ "$OS" == "Darwin" ]]; then
            # macOS: always use brew
            if brew list "$brew_name" &>/dev/null; then
                info "$brew_name already installed"
            else
                info "Installing $brew_name..."
                try brew install "$brew_name" && success "$brew_name installed"
            fi
        else
            # Linux: use apt if available, otherwise brew
            if [[ -n "$apt_name" ]]; then
                if dpkg -s "$apt_name" &>/dev/null; then
                    info "$apt_name already installed"
                else
                    info "Installing $apt_name..."
                    try sudo apt-get install -y "$apt_name" && success "$apt_name installed"
                fi
            else
                if brew list "$brew_name" &>/dev/null; then
                    info "$brew_name already installed (brew)"
                else
                    info "Installing $brew_name (brew)..."
                    try brew install "$brew_name" && success "$brew_name installed"
                fi
            fi
        fi
    done

    # Taps + tap packages
    local tap
    for tap in "${BREW_TAPS[@]}"; do
        brew tap "$tap" 2>/dev/null || true
    done
    local pkg
    for pkg in "${BREW_TAP_PACKAGES[@]}"; do
        local bin="${pkg##*/}"
        # --formula avoids hitting broken cask definitions in taps
        if brew list --formula "$bin" &>/dev/null; then
            info "$bin already installed"
        else
            info "Installing $bin..."
            try brew install --formula "$pkg" && success "$bin installed"
        fi
    done

    if [[ "$OS" == "Darwin" ]]; then
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

        # Docker Desktop
        if ! has docker; then
            info "Installing Docker Desktop..."
            try brew install --cask docker && success "Docker Desktop installed"
        else
            info "Docker already installed"
        fi
    else
        # oh-my-posh is installed on Linux via BREW_TAP_PACKAGES above

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
            # Avoid piping into sudo — the sudo() wrapper uses stdin for
            # the password, which would hijack tee's input. Use sh -c
            # with the path passed as a positional argument ($1) instead.
            sudo sh -c 'printf "%s\n" "$1" >> /etc/shells' _ "$zsh_path"
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

    # Use delta for diffs if available
    if has delta; then
        git config --global core.pager delta
        git config --global interactive.diffFilter 'delta --color-only'
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global merge.conflictstyle diff3
        info "Git pager set to delta"
    fi
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
    self_update "$@"

    printf '\033[1;36m'
    printf '  ┌──────────────────────────┐\n'
    printf '  │     dotfiles installer    │\n'
    printf '  └──────────────────────────┘\n'
    printf '\033[0m'
    printf '  OS: %s | Dotfiles: %s\n' "$OS" "$DOTFILES"
    log "OS: $OS | Dotfiles: $DOTFILES"

    prime_sudo
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
        clear_sudo_password
        exec zsh -l
    fi
}

main "$@"
