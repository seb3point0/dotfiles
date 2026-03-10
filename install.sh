#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# dotfiles installer — works on macOS and Linux
# Installs brew, shell tooling, and symlinks configs.
# Safe to re-run: skips anything already present.
#
# Fresh install: curl -fsSL https://raw.githubusercontent.com/seb3point0/dotfiles/main/install.sh | bash
# ============================================================================

bootstrap_info() { printf '[bootstrap] %s\n' "$*"; }
bootstrap_fail() { printf '[bootstrap] %s\n' "$*" >&2; exit 1; }

ensure_bootstrap_brew() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        return
    fi

    if command -v brew >/dev/null 2>&1; then
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        bootstrap_fail "curl is required to install Homebrew on macOS"
    fi

    bootstrap_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
        bootstrap_fail "Homebrew install failed"

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    command -v brew >/dev/null 2>&1 || bootstrap_fail "Homebrew install completed but brew is not on PATH"
}

install_git_with_native_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        bootstrap_info "Installing git with apt..."
        apt-get update && apt-get install -y git
    elif command -v dnf >/dev/null 2>&1; then
        bootstrap_info "Installing git with dnf..."
        dnf install -y git
    elif command -v yum >/dev/null 2>&1; then
        bootstrap_info "Installing git with yum..."
        yum install -y git
    elif command -v apk >/dev/null 2>&1; then
        bootstrap_info "Installing git with apk..."
        apk add --no-cache git
    elif command -v pacman >/dev/null 2>&1; then
        bootstrap_info "Installing git with pacman..."
        pacman -Sy --noconfirm git
    elif command -v zypper >/dev/null 2>&1; then
        bootstrap_info "Installing git with zypper..."
        zypper --non-interactive install git
    else
        bootstrap_fail "No supported package manager found to install git"
    fi
}

ensure_bootstrap_git() {
    local os
    os="$(uname -s)"

    if [[ "$os" == "Darwin" ]]; then
        ensure_bootstrap_brew
        if ! command -v git >/dev/null 2>&1; then
            bootstrap_info "Installing git with Homebrew..."
            brew install git || bootstrap_fail "git install failed"
        fi
        return
    fi

    if ! command -v git >/dev/null 2>&1; then
        install_git_with_native_package_manager || bootstrap_fail "git install failed"
    fi
}

# If not running from a file (e.g. curl | bash), clone/pull the repo and re-exec
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    _dotfiles="$HOME/.dotfiles"
    _repo="https://github.com/seb3point0/dotfiles.git"
    ensure_bootstrap_git
    if [[ -d "$_dotfiles/.git" ]]; then
        echo "Dotfiles already at $_dotfiles — pulling latest..."
        git -C "$_dotfiles" pull --ff-only
    else
        echo "Cloning dotfiles to $_dotfiles..."
        git clone "$_repo" "$_dotfiles"
    fi
    if [[ -r /dev/tty ]]; then
        exec bash "$_dotfiles/install.sh" "$@" </dev/tty >/dev/tty 2>&1
    fi
    exec bash "$_dotfiles/install.sh" "$@"
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_STATE_FILE="$HOME/.dotfiles-install-state"
INSTALLER_MODE="${INSTALLER_MODE:-}"
INSTALLER_THEME="${INSTALLER_THEME:-}"
INSTALLER_SELECTED="${INSTALLER_SELECTED:-}"
INSTALLER_FIRST_RUN="${INSTALLER_FIRST_RUN:-1}"
INSTALLER_GUM_ENABLED="${INSTALLER_GUM_ENABLED:-}"

installer_categories() {
    cat <<'EOF'
zsh
tmux
neovim
python
node
ai
terminal
developer
EOF
}

installer_category_label() {
    case "$1" in
        zsh) printf '%s\n' 'Zsh and shell defaults' ;;
        tmux) printf '%s\n' 'Tmux terminal multiplexer' ;;
        neovim) printf '%s\n' 'Neovim editor setup' ;;
        python) printf '%s\n' 'Python via pyenv' ;;
        node) printf '%s\n' 'Node.js tooling' ;;
        ai) printf '%s\n' 'AI coding tools' ;;
        terminal) printf '%s\n' 'Terminal utilities' ;;
        developer) printf '%s\n' 'Developer CLI tools' ;;
        *) return 1 ;;
    esac
}

installer_category_tools() {
    case "$1" in
        zsh) printf '%s\n' zsh oh-my-zsh zsh-autosuggestions zsh-syntax-highlighting powerlevel10k meslo-nerd-font ;;
        tmux) printf '%s\n' tmux ;;
        neovim) printf '%s\n' neovim tree-sitter-cli nvim-config lazy-nvim ;;
        python) printf '%s\n' pyenv python ;;
        node) printf '%s\n' node npm ;;
        ai) printf '%s\n' claude codex opencode huggingface-cli ;;
        terminal) printf '%s\n' fzf bat eza ripgrep speedtest stripe ;;
        developer) printf '%s\n' git gh jq kubectl scw supabase claude-settings ;;
        *) return 1 ;;
    esac
}

category_label() {
    installer_category_label "$1"
}

category_description() {
    case "$1" in
        zsh) printf '%s\n' 'Shell defaults, prompt, completions, and daily command-line ergonomics.' ;;
        tmux) printf '%s\n' 'Terminal session management with clipboard-aware defaults.' ;;
        neovim) printf '%s\n' 'Editor setup, plugin manager, and syntax tooling for coding.' ;;
        python) printf '%s\n' 'Python runtime management with pyenv and a ready-to-code base toolchain.' ;;
        node) printf '%s\n' 'Node.js runtime and package tooling for JavaScript and TypeScript work.' ;;
        ai) printf '%s\n' 'AI coding CLIs and related helpers for assisted development workflows.' ;;
        terminal) printf '%s\n' 'Everyday terminal utilities for search, navigation, and output cleanup.' ;;
        developer) printf '%s\n' 'Core developer CLIs for git hosting, APIs, cloud, and project maintenance.' ;;
        *) return 1 ;;
    esac
}

category_preview_tools() {
    case "$1" in
        zsh) printf '%s\n' 'zsh, oh-my-zsh, powerlevel10k' ;;
        tmux) printf '%s\n' 'tmux' ;;
        neovim) printf '%s\n' 'neovim, lazy-nvim, tree-sitter-cli' ;;
        python) printf '%s\n' 'pyenv, python' ;;
        node) printf '%s\n' 'node, npm' ;;
        ai) printf '%s\n' 'claude, codex, opencode' ;;
        terminal) printf '%s\n' 'fzf, bat, eza, ripgrep' ;;
        developer) printf '%s\n' 'git, gh, jq, kubectl' ;;
        *) return 1 ;;
    esac
}

installer_has_gum() {
    command -v gum >/dev/null 2>&1
}

installer_is_macos() {
    [[ "$OS" == "Darwin" ]]
}

prepare_gum_terminal() {
    case "${TERM:-}" in
        ""|dumb) export TERM="screen-256color" ;;
    esac
}

nvim_headless_runs_cleanly() {
    local command output status
    command="$1"
    output="$(LANG="${2:-C.UTF-8}" LC_ALL="${2:-C.UTF-8}" nvim --headless -c "$command" -c "qa" 2>&1)"
    status=$?

    printf '%s' "$output"

    [[ $status -eq 0 ]] || return $status
    [[ "$output" == *"Error detected while processing"* ]] && return 1
    [[ "$output" == *" E"* ]] && return 1
    [[ "$output" == E* ]] && return 1
    return 0
}

installer_use_gum() {
    prepare_gum_terminal
    [[ -n "$INSTALLER_GUM_ENABLED" ]] && return 0
    installer_has_interactive_terminal && installer_has_gum
}

gum_arch() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s\n' x86_64 ;;
        arm64|aarch64) printf '%s\n' arm64 ;;
        *) return 1 ;;
    esac
}

install_gum_from_github() {
    local version arch tmpdir archive_name download_url bin_path target_bin
    version="0.14.5"
    arch="$(gum_arch)" || return 1
    tmpdir="$(mktemp -d)"
    archive_name="gum_${version}_Linux_${arch}.tar.gz"
    download_url="https://github.com/charmbracelet/gum/releases/download/v${version}/${archive_name}"
    target_bin="/usr/local/bin/gum"

    if ! command -v curl >/dev/null 2>&1; then
        rm -rf "$tmpdir"
        return 1
    fi

    if ! curl -fsSL "$download_url" -o "$tmpdir/$archive_name"; then
        rm -rf "$tmpdir"
        return 1
    fi

    tar -xzf "$tmpdir/$archive_name" -C "$tmpdir" || {
        rm -rf "$tmpdir"
        return 1
    }

    bin_path="$tmpdir/gum_${version}_Linux_${arch}/gum"
    [[ -x "$bin_path" ]] || {
        rm -rf "$tmpdir"
        return 1
    }

    install -m 0755 "$bin_path" "$target_bin" || {
        rm -rf "$tmpdir"
        return 1
    }

    rm -rf "$tmpdir"
}

ensure_gum() {
    if installer_has_gum; then
        return
    fi

    if [[ "$OS" == "Darwin" ]]; then
        install_brew
        install_brew_packages gum
    else
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get update || true
            if ! DEBIAN_FRONTEND=noninteractive apt-get install -y gum; then
                install_gum_from_github || true
            fi
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y gum || install_gum_from_github || true
        elif command -v yum >/dev/null 2>&1; then
            yum install -y gum || install_gum_from_github || true
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache gum || install_gum_from_github || true
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm gum || install_gum_from_github || true
        elif command -v zypper >/dev/null 2>&1; then
            zypper --non-interactive install gum || install_gum_from_github || true
        else
            install_gum_from_github || true
        fi
    fi

    installer_has_gum || warn "gum install failed - falling back to plain shell UI"
}

save_installer_state() {
    local theme selected first_run tmp_state state_dir
    if [[ $# -ge 1 ]]; then
        theme="$1"
    else
        theme="${INSTALLER_THEME:-}"
    fi
    if [[ $# -ge 2 ]]; then
        selected="$2"
    else
        selected="${INSTALLER_SELECTED:-}"
    fi
    if [[ $# -ge 3 ]]; then
        first_run="$3"
    else
        first_run="${INSTALLER_FIRST_RUN:-0}"
    fi

    INSTALLER_THEME="$theme"
    INSTALLER_SELECTED="$selected"
    INSTALLER_FIRST_RUN="$first_run"

    state_dir=$(dirname "$INSTALLER_STATE_FILE")
    mkdir -p "$state_dir"
    tmp_state=$(mktemp "$state_dir/.dotfiles-install-state.XXXXXX")
    cat > "$tmp_state" <<EOF
INSTALLER_THEME=$INSTALLER_THEME
INSTALLER_SELECTED=$INSTALLER_SELECTED
INSTALLER_FIRST_RUN=$INSTALLER_FIRST_RUN
EOF
    mv "$tmp_state" "$INSTALLER_STATE_FILE"
}

load_installer_state() {
    local line key value
    INSTALLER_THEME=""
    INSTALLER_SELECTED=""
    INSTALLER_FIRST_RUN=1

    if [[ -f "$INSTALLER_STATE_FILE" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            case "$line" in
                INSTALLER_THEME=*|INSTALLER_SELECTED=*|INSTALLER_FIRST_RUN=*) ;;
                *)
                    warn "Invalid installer state detected - resetting saved installer state"
                    INSTALLER_THEME=""
                    INSTALLER_SELECTED=""
                    INSTALLER_FIRST_RUN=1
                    rm -f "$INSTALLER_STATE_FILE"
                    return
                    ;;
            esac

            key=${line%%=*}
            value=${line#*=}

            if [[ "$value" =~ ^\'.*\'$ ]]; then
                value=${value#\'}
                value=${value%\'}
            fi

            case "$key" in
                INSTALLER_THEME) INSTALLER_THEME="$value" ;;
                INSTALLER_SELECTED) INSTALLER_SELECTED="$value" ;;
                INSTALLER_FIRST_RUN) INSTALLER_FIRST_RUN="$value" ;;
            esac
        done < "$INSTALLER_STATE_FILE"
    fi
}

installer_all_categories_csv() {
    installer_categories | paste -sd, -
}

installer_has_category() {
    local category
    category="$1"
    installer_categories | grep -qx "$category"
}

installer_selected_has_category() {
    local selected_csv category selected
    selected_csv="${1:-$INSTALLER_SELECTED}"
    category="$2"

    IFS=, read -r -a selected <<< "$selected_csv"
    for selected_category in "${selected[@]}"; do
        [[ "$selected_category" == "$category" ]] && return 0
    done

    return 1
}

validate_installer_categories_csv() {
    local csv category
    csv="$1"

    IFS=, read -r -a categories <<< "$csv"
    for category in "${categories[@]}"; do
        [[ -n "$category" ]] || fail "Empty category entry in: $csv"
        installer_has_category "$category" || fail "Unknown category: $category"
    done
}

set_installer_mode() {
    local new_mode
    new_mode="$1"

    if [[ -n "$INSTALLER_MODE" && "$INSTALLER_MODE" != "$new_mode" ]]; then
        fail "Conflicting installer modes: $INSTALLER_MODE and $new_mode"
    fi

    INSTALLER_MODE="$new_mode"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --update)
                set_installer_mode "update"
                shift
                ;;
            --reconfigure)
                set_installer_mode "reconfigure"
                shift
                ;;
            --all)
                INSTALLER_SELECTED="$(installer_all_categories_csv)"
                shift
                ;;
            --theme)
                [[ $# -ge 2 ]] || fail "Missing value for --theme"
                [[ "$2" != --* ]] || fail "Missing value for --theme"
                INSTALLER_THEME="$2"
                shift 2
                ;;
            --theme=*)
                INSTALLER_THEME="${1#--theme=}"
                [[ -n "$INSTALLER_THEME" ]] || fail "Missing value for --theme"
                [[ "$INSTALLER_THEME" != --* ]] || fail "Missing value for --theme"
                shift
                ;;
            --categories)
                [[ $# -ge 2 ]] || fail "Missing value for --categories"
                [[ "$2" != --* ]] || fail "Missing value for --categories"
                validate_installer_categories_csv "$2"
                INSTALLER_SELECTED="$2"
                shift 2
                ;;
            --categories=*)
                INSTALLER_SELECTED="${1#--categories=}"
                [[ -n "$INSTALLER_SELECTED" ]] || fail "Missing value for --categories"
                [[ "$INSTALLER_SELECTED" != --* ]] || fail "Missing value for --categories"
                validate_installer_categories_csv "$INSTALLER_SELECTED"
                shift
                ;;
            *)
                fail "Unknown argument: $1"
                ;;
        esac
    done
}

THEME_NAME="${THEME_NAME:-}"
THEME_PRIMARY="${THEME_PRIMARY:-}"
THEME_ACCENT="${THEME_ACCENT:-}"
THEME_SUCCESS="${THEME_SUCCESS:-}"
THEME_WARNING="${THEME_WARNING:-}"
THEME_MUTED="${THEME_MUTED:-}"
THEME_RESET="${THEME_RESET:-$'\033[0m'}"

set_theme() {
    local theme
    theme="${1:-opencode}"

    case "$theme" in
        opencode)
            THEME_NAME="opencode"
            THEME_PRIMARY=$'\033[38;5;45m'
            THEME_ACCENT=$'\033[1;37m'
            THEME_SUCCESS=$'\033[38;5;42m'
            THEME_WARNING=$'\033[38;5;220m'
            THEME_MUTED=$'\033[38;5;245m'
            ;;
        amber)
            THEME_NAME="amber"
            THEME_PRIMARY=$'\033[38;5;214m'
            THEME_ACCENT=$'\033[1;33m'
            THEME_SUCCESS=$'\033[38;5;178m'
            THEME_WARNING=$'\033[38;5;223m'
            THEME_MUTED=$'\033[38;5;246m'
            ;;
        mono)
            THEME_NAME="mono"
            THEME_PRIMARY=$'\033[1;37m'
            THEME_ACCENT=$'\033[0;37m'
            THEME_SUCCESS=$'\033[0;32m'
            THEME_WARNING=$'\033[1;30m'
            THEME_MUTED=$'\033[0;90m'
            ;;
        *)
            warn "Unknown theme '$theme' - falling back to opencode"
            set_theme opencode
            return
            ;;
    esac

    INSTALLER_THEME="$THEME_NAME"
}

render_header() {
    local title subtitle
    title="${1:-}"
    subtitle="${2:-}"

    printf '\n%b%s%b\n' "$THEME_PRIMARY" "$title" "$THEME_RESET"
    if [[ -n "$subtitle" ]]; then
        printf '%b%s%b\n' "$THEME_MUTED" "$subtitle" "$THEME_RESET"
    fi
}

render_menu_row() {
    local index label detail marker
    index="${1:-}"
    label="${2:-}"
    detail="${3:-}"
    marker="${4:- }"

    printf '%b[%s]%b %b%s%b' "$THEME_PRIMARY" "$index" "$THEME_RESET" "$THEME_ACCENT" "$label" "$THEME_RESET"
    if [[ -n "$detail" ]]; then
        printf ' %b%s%b' "$THEME_MUTED" "$detail" "$THEME_RESET"
    fi
    if [[ -n "$marker" ]]; then
        printf ' %b%s%b' "$THEME_SUCCESS" "$marker" "$THEME_RESET"
    fi
    printf '\n'
}

gum_theme_foreground() {
    case "${INSTALLER_THEME:-opencode}" in
        amber) printf '%s\n' '#ff9d00' ;;
        mono) printf '%s\n' '#f5f5f5' ;;
        *) printf '%s\n' '#00d7ff' ;;
    esac
}

gum_theme_muted() {
    case "${INSTALLER_THEME:-opencode}" in
        amber) printf '%s\n' '#a6a6a6' ;;
        mono) printf '%s\n' '#9a9a9a' ;;
        *) printf '%s\n' '#8a8f98' ;;
    esac
}

gum_theme_success() {
    case "${INSTALLER_THEME:-opencode}" in
        amber) printf '%s\n' '#d6b86a' ;;
        mono) printf '%s\n' '#cfcfcf' ;;
        *) printf '%s\n' '#33d17a' ;;
    esac
}

installer_platform_summary() {
    if installer_is_macos; then
        printf '%s\n' 'Homebrew first for core packages and dotfiles tools.'
        return
    fi

    printf '%s\n' 'Native Linux packages first, Homebrew only when a bundle needs it.'
}

gum_page() {
    local title subtitle
    title="$1"
    subtitle="${2:-}"

    if installer_use_gum; then
        gum style --foreground "$(gum_theme_foreground)" --bold "$title"
        [[ -n "$subtitle" ]] && gum style --foreground "$(gum_theme_muted)" "$subtitle"
        printf '\n'
        return
    fi

    render_header "$title" "$subtitle"
}

gum_section() {
    local title body
    title="$1"
    body="${2:-}"

    if installer_use_gum; then
        gum style --foreground "$(gum_theme_foreground)" --bold "$title"
        [[ -n "$body" ]] && gum style --foreground "$(gum_theme_muted)" "$body"
        return
    fi

    printf '%s\n' "$title"
    [[ -n "$body" ]] && printf '%s\n' "$body"
}

gum_note() {
    local body
    body="$1"

    if installer_use_gum; then
        gum style --border normal --border-foreground "$(gum_theme_muted)" --padding "0 1" "$body"
        return
    fi

    printf '%s\n' "$body"
}

gum_summary_card() {
    local title body
    title="$1"
    body="$2"

    if installer_use_gum; then
        gum style --border normal --border-foreground "$(gum_theme_foreground)" --padding "1 2" --margin "0 0 1 0" --width 88 "$title

$body"
        return
    fi

    printf '%s\n%s\n' "$title" "$body"
}

gum_header() {
    gum_page "$1" "${2:-}"
}

gum_show_welcome() {
    local body

    if ! installer_use_gum; then
        return
    fi

    gum_page "dotfiles installer" "A guided setup for this machine."
    printf -v body 'OS: %s\nStrategy: %s\nFlow: %s' "$OS" "$(installer_platform_summary)" 'theme -> bundles -> review -> install'
    gum_summary_card "Welcome" "$body"
    gum_note "Use arrow keys to move, space to toggle when available, and enter to continue."
}

gum_select_theme() {
    local choice
    if installer_use_gum; then
        gum_page "Theme" "Choose the installer look and feel."
        gum_note "This only changes installer presentation, not your shell theme or terminal config."
        choice="$(printf '%s\n' \
            'opencode - Bright cyan accents for the default installer look' \
            'amber - Warm terminal tones with softer contrast' \
            'mono - Neutral grayscale styling with minimal color' \
            | gum choose --header "Theme" --cursor.foreground "$(gum_theme_foreground)" --selected.foreground "$(gum_theme_success)")"
        choice="${choice%% - *}"
        set_theme "$choice"
        return
    fi
    show_theme_picker
}

gum_select_existing_mode() {
    local choice
    if installer_use_gum; then
        gum_page "Setup mode" "Choose how to continue with this machine."
        choice="$(printf '%s\n' update reconfigure theme exit | gum choose --header "Existing install" --cursor.foreground "$(gum_theme_foreground)" --selected.foreground "$(gum_theme_success)")"
        case "$choice" in
            update|reconfigure) INSTALLER_MODE="$choice" ;;
            theme) gum_select_theme; INSTALLER_MODE="menu" ;;
            exit) exit 0 ;;
        esac
        return
    fi
    show_existing_install_menu
}

gum_select_categories() {
    local selected=() line csv options=() category
    if installer_use_gum; then
        gum_page "Bundles" "Select the setup bundles for this machine."
        gum_note "Choose what this machine needs now. Unselected bundles can be added later by rerunning the installer."
        while IFS= read -r category; do
            options+=("$category - $(category_label "$category") - $(category_description "$category")")
        done < <(installer_categories)
        while IFS= read -r line; do
            selected+=("$line")
        done < <(
            printf '%s\n' "${options[@]}" \
                | gum choose --no-limit --header "Categories" --cursor.foreground "$(gum_theme_foreground)" --selected.foreground "$(gum_theme_success)"
        )
        if [[ ${#selected[@]} -eq 0 ]]; then
            csv="$(installer_all_categories_csv)"
        else
            csv="$(printf '%s\n' "${selected[@]}" | sed 's/ - .*//' | paste -sd, -)"
        fi
        printf '%s\n' "$csv"
        return
    fi
    installer_multiselect "$@"
}

gum_review_selection() {
    local category body note
    if installer_use_gum; then
        printf -v body 'Theme: %s\nPlatform: %s\n\n' "${INSTALLER_THEME:-opencode}" "$(installer_platform_summary)"
        while IFS= read -r category; do
            installer_selected_has_category "$INSTALLER_SELECTED" "$category" || continue
            printf -v body '%s%s\n%s\nIncludes: %s\n\n' "$body" "$(category_label "$category")" "$(category_description "$category")" "$(category_preview_tools "$category")"
        done < <(installer_categories)
        gum_page "Review" "Confirm what will be installed before any changes begin."
        gum_summary_card "Selected bundles" "$body"
        note="Linux keeps native packages first and only uses Homebrew when a chosen bundle needs it."
        installer_is_macos && note="macOS installs Homebrew-backed packages first, then applies the selected dotfile bundles."
        gum_note "$note"
        return
    fi
    show_review_screen
}

gum_confirm_install() {
    if installer_use_gum; then
        gum confirm "Start installing the selected bundles?"
        return
    fi
    return 0
}

gum_finish_summary() {
    local selected_csv category state successes failures body next_step
    selected_csv="${1:-$INSTALLER_SELECTED}"
    successes=""
    failures=""

    while IFS= read -r category; do
        [[ -n "$selected_csv" ]] && ! installer_selected_has_category "$selected_csv" "$category" && continue
        state="$(get_task_state "$category")"
        case "$state" in
            done) printf -v successes '%s- %s\n' "$successes" "$(category_label "$category")" ;;
            failed) printf -v failures '%s- %s\n' "$failures" "$(category_label "$category")" ;;
        esac
    done < <(installer_categories)

    [[ -z "$successes" ]] && successes=$'- none\n'
    [[ -z "$failures" ]] && failures=$'- none\n'
    printf -v next_step '%s\n%s\n%s\n%s' \
        'Machine-specific config goes in ~/.zshrc.local' \
        'Run p10k configure to customize your prompt' \
        'Open nvim and run :Lazy to check plugin status' \
        'Set your terminal font to MesloLGS Nerd Font (or another Nerd Font)'
    printf -v body 'Succeeded:\n%s\nFailed:\n%s\nNext:\n%s' "$successes" "$failures" "$next_step"
    gum_summary_card "Finished" "$body"
}

run_with_gum_spinner() {
    local title
    title="$1"
    shift
    if installer_use_gum; then
        if declare -F "$1" >/dev/null 2>&1; then
            INSTALLER_TEST_MODE=1 gum spin --spinner dot --title "$title" -- \
                bash -lc 'installer_source="$1"; shift; cmd=("$@"); set --; source "$installer_source"; "${cmd[@]}"' _ "$DOTFILES_DIR/install.sh" "$@"
            return
        fi
        gum spin --spinner dot --title "$title" -- "$@"
        return
    fi
    "$@"
}

installer_has_interactive_terminal() {
    [[ -t 0 && -t 1 && -z "${INSTALLER_TEST_MODE:-}" ]]
}

installer_supports_advanced_input() {
    installer_has_interactive_terminal && command -v tput >/dev/null 2>&1
}

installer_numbered_choice() {
    local prompt default_choice max_choice choice
    prompt="$1"
    default_choice="$2"
    max_choice="$3"

    if ! installer_has_interactive_terminal; then
        printf '%s\n' "$default_choice"
        return
    fi

    while true; do
        read -r -p "$prompt" choice
        choice="${choice:-$default_choice}"
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && (( choice >= 1 && choice <= max_choice )); then
            printf '%s\n' "$choice"
            return
        fi
        warn "Enter a number between 1 and $max_choice"
    done
}

install_linux_packages() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        bootstrap_info "Installing packages with apt: ${packages[*]}"
        DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "${packages[@]}"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "${packages[@]}"
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "${packages[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "${packages[@]}"
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install "${packages[@]}"
    else
        warn "No supported Linux package manager found for: ${packages[*]}"
    fi
}

install_category_packages() {
    local linux_packages=()
    local brew_packages=()
    local token

    for token in "$@"; do
        case "$token" in
            git|zsh|tmux|neovim|node|gh|jq|kubectl|ripgrep|fzf)
                linux_packages+=("$token")
                ;;
            tree-sitter-cli)
                linux_packages+=(tree-sitter-cli)
                ;;
            eza)
                linux_packages+=(eza)
                ;;
            bat)
                linux_packages+=(bat)
                ;;
            pyenv)
                brew_packages+=(pyenv)
                ;;
            huggingface-cli|scw)
                brew_packages+=("$token")
                ;;
            *)
                brew_packages+=("$token")
                ;;
        esac
    done

    if [[ "$OS" == "Linux" ]]; then
        install_linux_packages "${linux_packages[@]}"
        if [[ ${#brew_packages[@]} -gt 0 ]]; then
            install_brew
            install_brew_packages "${brew_packages[@]}"
        fi
    else
        install_brew
        install_brew_packages "$@"
    fi
}

installer_menu_select() {
    local title subtitle default_choice selected_key key escape_sequence
    title="$1"
    subtitle="$2"
    default_choice="$3"
    shift 3
    local options=("$@")
    local selected_index=$((default_choice - 1))

    if ! installer_supports_advanced_input; then
        render_header "$title" "$subtitle" >&2
        local i label detail
        for i in "${!options[@]}"; do
            IFS='|' read -r _ label detail <<< "${options[$i]}"
            render_menu_row "$((i + 1))" "$label" "$detail" "" >&2
        done
        installer_numbered_choice "Choose [1-${#options[@]}] (default: $default_choice): " "$default_choice" "${#options[@]}"
        return
    fi

    while true; do
        printf '\033[2J\033[H' >&2
        render_header "$title" "$subtitle" >&2

        local i label detail marker
        for i in "${!options[@]}"; do
            IFS='|' read -r _ label detail <<< "${options[$i]}"
            marker=""
            if (( i == selected_index )); then
                marker="<"
            fi
            render_menu_row "$((i + 1))" "$label" "$detail" "$marker" >&2
        done

        printf '%bUse arrow keys or j/k, then press Enter.%b\n' "$THEME_MUTED" "$THEME_RESET" >&2

        read -rsn1 key
        case "$key" in
            $'\n'|$'\r')
                printf '%s\n' "$((selected_index + 1))"
                return
                ;;
            k)
                selected_index=$(((selected_index - 1 + ${#options[@]}) % ${#options[@]}))
                ;;
            j)
                selected_index=$(((selected_index + 1) % ${#options[@]}))
                ;;
            $'\033')
                read -rsn2 escape_sequence || true
                case "$escape_sequence" in
                    '[A') selected_index=$(((selected_index - 1 + ${#options[@]}) % ${#options[@]})) ;;
                    '[B') selected_index=$(((selected_index + 1) % ${#options[@]})) ;;
                esac
                ;;
            [1-9])
                if (( key >= 1 && key <= ${#options[@]} )); then
                    printf '%s\n' "$key"
                    return
                fi
                ;;
        esac
    done
}

installer_multiselect() {
    local title subtitle
    title="$1"
    subtitle="$2"
    shift 2
    local options=("$@")
    local selected_index=0
    local selected_csv="${INSTALLER_SELECTED:-$(installer_all_categories_csv)}"
    local key escape_sequence i value label detail marker prefix

    if ! installer_supports_advanced_input; then
        printf '%s\n' "$selected_csv"
        return
    fi

    while true; do
        printf '\033[2J\033[H' >&2
        render_header "$title" "$subtitle" >&2

        for i in "${!options[@]}"; do
            IFS='|' read -r value label detail <<< "${options[$i]}"
            if installer_selected_has_category "$selected_csv" "$value"; then
                prefix="x"
            else
                prefix=" "
            fi
            marker=""
            if (( i == selected_index )); then
                marker="<"
            fi
            render_menu_row "$prefix" "$label" "$detail" "$marker" >&2
        done

        printf '%bUse arrow keys or j/k to move, space to toggle, Enter to continue.%b\n' "$THEME_MUTED" "$THEME_RESET" >&2

        read -rsn1 key
        case "$key" in
            ' ')
                IFS='|' read -r value _ <<< "${options[$selected_index]}"
                INSTALLER_SELECTED="$selected_csv"
                toggle_category "$value"
                selected_csv="$INSTALLER_SELECTED"
                ;;
            $'\n'|$'\r')
                printf '%s\n' "$selected_csv"
                return
                ;;
            k)
                selected_index=$(((selected_index - 1 + ${#options[@]}) % ${#options[@]}))
                ;;
            j)
                selected_index=$(((selected_index + 1) % ${#options[@]}))
                ;;
            $'\033')
                read -rsn2 escape_sequence || true
                case "$escape_sequence" in
                    '[A') selected_index=$(((selected_index - 1 + ${#options[@]}) % ${#options[@]})) ;;
                    '[B') selected_index=$(((selected_index + 1) % ${#options[@]})) ;;
                esac
                ;;
        esac
    done
}

choose_default_mode() {
    if [[ -n "$INSTALLER_MODE" ]]; then
        return
    fi

    if [[ "${INSTALLER_FIRST_RUN:-1}" == "1" ]]; then
        INSTALLER_MODE="wizard"
    else
        INSTALLER_MODE="menu"
    fi
}

show_existing_install_menu() {
    if installer_use_gum; then
        gum_select_existing_mode
        return
    fi
    local selection
    selection="$(installer_menu_select \
        "dotfiles installer" \
        "Choose how to continue with your existing setup." \
        "1" \
        "update|Update current setup|Re-run installs with saved selections" \
        "reconfigure|Reconfigure categories|Pick a different set of tools" \
        "theme|Change theme|Switch installer colors before continuing")"

    case "$selection" in
        1) INSTALLER_MODE="update" ;;
        2) INSTALLER_MODE="reconfigure" ;;
        3)
            show_theme_picker
            INSTALLER_MODE="menu"
            ;;
        *) fail "Unknown installer menu selection: $selection" ;;
    esac
}

show_theme_picker() {
    if installer_use_gum; then
        gum_select_theme
        return
    fi
    local selection
    selection="$(installer_menu_select \
        "Choose a theme" \
        "Pick the installer look and feel." \
        "1" \
        "opencode|OpenCode|Bright cyan accents" \
        "amber|Amber|Warm terminal tones" \
        "mono|Mono|Minimal grayscale palette")"

    case "$selection" in
        1) set_theme opencode ;;
        2) set_theme amber ;;
        3) set_theme mono ;;
        *) fail "Unknown theme selection: $selection" ;;
    esac
}

select_default_categories() {
    INSTALLER_SELECTED="$(installer_all_categories_csv)"
}

toggle_category() {
    local category updated=() existing
    category="$1"

    installer_has_category "$category" || fail "Unknown category: $category"

    for existing in $(installer_categories); do
        if [[ "$existing" == "$category" ]]; then
            if installer_selected_has_category "$INSTALLER_SELECTED" "$category"; then
                continue
            fi
            updated+=("$existing")
            continue
        fi

        if installer_selected_has_category "$INSTALLER_SELECTED" "$existing"; then
            updated+=("$existing")
        fi
    done

    INSTALLER_SELECTED="$(IFS=,; printf '%s' "${updated[*]}")"
}

show_category_details() {
    local category label
    category="$1"
    installer_has_category "$category" || fail "Unknown category: $category"
    label="$(installer_category_label "$category")"

    render_header "$label" "$category"
    printf '%bIncludes:%b\n' "$THEME_MUTED" "$THEME_RESET"
    while IFS= read -r tool; do
        printf '  - %s\n' "$tool"
    done < <(installer_category_tools "$category")
}

show_review_screen() {
    if installer_use_gum; then
        gum_review_selection
        return
    fi
    local category label

    render_header "Review selections" "Check the categories queued for install."
    render_menu_row "-" "Theme" "${INSTALLER_THEME:-opencode}" ""

    if [[ -z "$INSTALLER_SELECTED" ]]; then
        render_menu_row "-" "Categories" "None selected" ""
        return
    fi

    while IFS= read -r category; do
        if ! installer_selected_has_category "$INSTALLER_SELECTED" "$category"; then
            continue
        fi

        label="$(installer_category_label "$category")"
        render_menu_row "-" "$label" "$category" ""
        printf '%b    %s%b\n' "$THEME_MUTED" "$(installer_category_tools "$category" | paste -sd, -)" "$THEME_RESET"
    done < <(installer_categories)
}

installer_task_state_var() {
    printf 'INSTALLER_TASK_STATE_%s' "$1"
}

mark_task_state() {
    local category state state_var
    category="$1"
    state="$2"

    installer_has_category "$category" || fail "Unknown category: $category"

    case "$state" in
        pending|running|done|skipped|failed) ;;
        *) fail "Unknown task state: $state" ;;
    esac

    state_var="$(installer_task_state_var "$category")"
    printf -v "$state_var" '%s' "$state"
}

get_task_state() {
    local category state_var state
    category="$1"

    installer_has_category "$category" || fail "Unknown category: $category"

    state_var="$(installer_task_state_var "$category")"
    state="${!state_var:-pending}"
    printf '%s\n' "$state"
}

initialize_task_states() {
    local selected_csv category
    selected_csv="${1:-$INSTALLER_SELECTED}"

    while IFS= read -r category; do
        mark_task_state "$category" skipped
    done < <(installer_categories)

    if [[ -z "$selected_csv" ]]; then
        selected_csv="$(installer_all_categories_csv)"
    fi

    validate_installer_categories_csv "$selected_csv"
    IFS=, read -r -a categories <<< "$selected_csv"
    for category in "${categories[@]}"; do
        mark_task_state "$category" pending
    done
}

task_state_marker() {
    case "$1" in
        pending) printf '%s\n' 'pending' ;;
        running) printf '%s\n' 'running' ;;
        done) printf '%s\n' 'done' ;;
        skipped) printf '%s\n' 'skipped' ;;
        failed) printf '%s\n' 'failed' ;;
    esac
}

task_state_color() {
    case "$1" in
        pending) printf '%s\n' "$THEME_MUTED" ;;
        running) printf '%s\n' "$THEME_PRIMARY" ;;
        done) printf '%s\n' "$THEME_SUCCESS" ;;
        skipped) printf '%s\n' "$THEME_WARNING" ;;
        failed) printf '%s\n' "$RED" ;;
        *) printf '%s\n' "$THEME_MUTED" ;;
    esac
}

render_execution_screen() {
    local selected_csv category label state color marker
    selected_csv="${1:-$INSTALLER_SELECTED}"

    if [[ -z "${INSTALLER_TEST_MODE:-}" ]] && installer_has_interactive_terminal; then
        printf '\033[2J\033[H'
    fi

    if installer_use_gum; then
        gum_page "Installing" "Working through the selected bundles one at a time."
    else
        render_header "Installing dotfiles" "Live progress by category."
    fi
    while IFS= read -r category; do
        if ! installer_selected_has_category "$selected_csv" "$category"; then
            continue
        fi

        label="$(installer_category_label "$category")"
        state="$(get_task_state "$category")"
        color="$(task_state_color "$state")"
        marker="$(task_state_marker "$state")"

        printf '%b[%s]%b %b%s%b %b%s%b\n' \
            "$color" "$marker" "$THEME_RESET" \
            "$THEME_ACCENT" "$label" "$THEME_RESET" \
            "$THEME_MUTED" "$category" "$THEME_RESET"
    done < <(installer_categories)
}

render_final_summary() {
    local selected_csv category label state pending_count running_count done_count skipped_count failed_count
    selected_csv="${1:-$INSTALLER_SELECTED}"

    if installer_use_gum; then
        gum_finish_summary "$selected_csv"
        return
    fi

    pending_count=0
    running_count=0
    done_count=0
    skipped_count=0
    failed_count=0

    render_header "Installer summary" "Final category results."
    while IFS= read -r category; do
        if [[ -n "$selected_csv" ]] && ! installer_selected_has_category "$selected_csv" "$category"; then
            continue
        fi

        state="$(get_task_state "$category")"
        case "$state" in
            pending) pending_count=$((pending_count + 1)) ;;
            running) running_count=$((running_count + 1)) ;;
            done) done_count=$((done_count + 1)) ;;
            skipped) skipped_count=$((skipped_count + 1)) ;;
            failed) failed_count=$((failed_count + 1)) ;;
        esac

        label="$(installer_category_label "$category")"
        printf '  - %s: %s\n' "$label" "$state"
    done < <(installer_categories)

    printf '\n'
    printf '  done: %s\n' "$done_count"
    printf '  skipped: %s\n' "$skipped_count"
    printf '  failed: %s\n' "$failed_count"
    printf '  pending: %s\n' "$pending_count"
    printf '  running: %s\n' "$running_count"
}

show_category_checklist() {
    local category choice action

    if [[ -z "$INSTALLER_SELECTED" ]]; then
        select_default_categories
    fi

    if installer_use_gum; then
        INSTALLER_SELECTED="$(gum_select_categories)"
        return
    fi

    if installer_supports_advanced_input; then
        INSTALLER_SELECTED="$(installer_multiselect \
            "Choose categories" \
            "Use arrows or j/k to move, space to toggle, Enter to continue." \
            "zsh|$(installer_category_label zsh)|zsh" \
            "tmux|$(installer_category_label tmux)|tmux" \
            "neovim|$(installer_category_label neovim)|neovim" \
            "python|$(installer_category_label python)|python" \
            "node|$(installer_category_label node)|node" \
            "ai|$(installer_category_label ai)|ai" \
            "terminal|$(installer_category_label terminal)|terminal" \
            "developer|$(installer_category_label developer)|developer")"
        return
    fi

    while true; do
        render_header "Choose categories" "Toggle bundles for this machine, review, or continue."
        while IFS= read -r category; do
            if installer_selected_has_category "$INSTALLER_SELECTED" "$category"; then
                render_menu_row "x" "$(installer_category_label "$category")" "$category" "on"
            else
                render_menu_row " " "$(installer_category_label "$category")" "$category" "off"
            fi
        done < <(installer_categories)

        printf '%bActions:%b\n' "$THEME_MUTED" "$THEME_RESET"
        printf '  1) Toggle a category\n'
        printf '  2) View category details\n'
        printf '  3) Review selection\n'
        printf '  4) Continue\n'

        choice="$(installer_numbered_choice "Choose [1-4] (default: 4): " "4" "4")"
        case "$choice" in
            1)
                category="$(installer_menu_select \
                    "Toggle category" \
                    "Choose a bundle to enable or disable." \
                    "1" \
                    "zsh|$(installer_category_label zsh)|zsh" \
                    "tmux|$(installer_category_label tmux)|tmux" \
                    "neovim|$(installer_category_label neovim)|neovim" \
                    "python|$(installer_category_label python)|python" \
                    "node|$(installer_category_label node)|node" \
                    "ai|$(installer_category_label ai)|ai" \
                    "terminal|$(installer_category_label terminal)|terminal" \
                    "developer|$(installer_category_label developer)|developer")"
                case "$category" in
                    1) action="zsh" ;;
                    2) action="tmux" ;;
                    3) action="neovim" ;;
                    4) action="python" ;;
                    5) action="node" ;;
                    6) action="ai" ;;
                    7) action="terminal" ;;
                    8) action="developer" ;;
                    *) fail "Unknown category selection: $category" ;;
                esac
                toggle_category "$action"
                ;;
            2)
                category="$(installer_menu_select \
                    "Category details" \
                    "Inspect the tools bundled in a category." \
                    "1" \
                    "zsh|$(installer_category_label zsh)|zsh" \
                    "tmux|$(installer_category_label tmux)|tmux" \
                    "neovim|$(installer_category_label neovim)|neovim" \
                    "python|$(installer_category_label python)|python" \
                    "node|$(installer_category_label node)|node" \
                    "ai|$(installer_category_label ai)|ai" \
                    "terminal|$(installer_category_label terminal)|terminal" \
                    "developer|$(installer_category_label developer)|developer")"
                case "$category" in
                    1) show_category_details zsh ;;
                    2) show_category_details tmux ;;
                    3) show_category_details neovim ;;
                    4) show_category_details python ;;
                    5) show_category_details node ;;
                    6) show_category_details ai ;;
                    7) show_category_details terminal ;;
                    8) show_category_details developer ;;
                    *) fail "Unknown category detail selection: $category" ;;
                esac
                if installer_has_interactive_terminal; then
                    read -r -p "Press Enter to return to categories..." action
                fi
                ;;
            3)
                show_review_screen
                if installer_has_interactive_terminal; then
                    read -r -p "Press Enter to return to categories..." action
                fi
                ;;
            4)
                return
                ;;
        esac
    done
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[dotfiles]${NC} $*"; }
success() { echo -e "${GREEN}[dotfiles]${NC} $*"; }
warn()    { echo -e "${YELLOW}[dotfiles]${NC} $*"; }
fail()    { echo -e "${RED}[dotfiles]${NC} $*"; exit 1; }
section() {
    echo
    echo -e "${CYAN}==>${NC} $*"
}
step()    { echo -e "${CYAN}  ->${NC} $*"; }
summary() {
    echo
    echo -e "${CYAN}Summary:${NC}"
    for item in "$@"; do
        echo "  - $item"
    done
}

refresh_dotfiles_repo() {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        return
    fi

    if ! git -C "$DOTFILES_DIR" remote get-url origin &>/dev/null; then
        warn "No git origin configured for $DOTFILES_DIR - skipping update check"
        return
    fi

    info "Getting latest dotfiles commit from GitHub..."
    git -C "$DOTFILES_DIR" pull --ff-only

    local commit_info
    commit_info="$(git -C "$DOTFILES_DIR" log -1 --date=short --format='%cd %h')"
    info "Using dotfiles commit $commit_info"
}

ensure_git_identity() {
    if ! command -v git &>/dev/null; then
        warn "git not found - skipping Git identity check"
        return
    fi

    local git_name git_email
    git_name="$(git config --global --get user.name || true)"
    git_email="$(git config --global --get user.email || true)"

    if [[ -n "$git_name" && -n "$git_email" ]]; then
        info "Git identity already set: $git_name <$git_email>"
        return
    fi

    if [[ ! -t 0 ]]; then
        warn "Git user.name or user.email is missing - run 'git config --global' after install"
        return
    fi

    section "Git identity"

    if [[ -z "$git_name" ]]; then
        read -r -p "  Git user.name: " git_name
        if [[ -n "$git_name" ]]; then
            git config --global user.name "$git_name"
            success "Set git user.name to '$git_name'"
        else
            warn "Skipped git user.name"
        fi
    else
        info "Git user.name already set: $git_name"
    fi

    if [[ -z "$git_email" ]]; then
        read -r -p "  Git user.email: " git_email
        if [[ -n "$git_email" ]]; then
            git config --global user.email "$git_email"
            success "Set git user.email to '$git_email'"
        else
            warn "Skipped git user.email"
        fi
    else
        info "Git user.email already set: $git_email"
    fi
}

OS="$(uname -s)"

if [[ -z "${INSTALLER_TEST_MODE:-}" ]]; then
    refresh_dotfiles_repo
fi

# ============================================================================
# Homebrew
# ============================================================================

install_brew() {
    step "Checking Homebrew"
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
    step "Installing brew packages"

    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        packages=(
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
            huggingface-cli
            jq
            kubectl
            pyenv
            scw
        )
    fi

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
# Python / pyenv
# ============================================================================

PYENV_PYTHON_VERSION="3.14.3"

install_python_env() {
    step "Preparing Python environment"
    if ! command -v pyenv &>/dev/null; then
        warn "pyenv not found - skipping Python environment setup"
        return
    fi

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    if pyenv versions --bare | grep -qx "$PYENV_PYTHON_VERSION"; then
        info "Python $PYENV_PYTHON_VERSION already installed via pyenv"
    else
        info "Installing Python $PYENV_PYTHON_VERSION via pyenv..."
        pyenv install "$PYENV_PYTHON_VERSION"
    fi

    pyenv global "$PYENV_PYTHON_VERSION"
    pyenv rehash
    success "Python $PYENV_PYTHON_VERSION ready via pyenv"
}

# ============================================================================
# Tap packages (third-party brew taps)
# ============================================================================

install_tap_packages() {
    step "Installing tap packages"

    # Format: "tap/formula" — brew installs the tap automatically
    # Note: scw is in homebrew-core, installed via install_brew_packages instead
    local tap_packages=("$@")

    if [[ ${#tap_packages[@]} -eq 0 ]]; then
        tap_packages=(
            "teamookla/speedtest/speedtest"
            "supabase/tap/supabase"
        )
    fi

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
    local root_prefix=""
    step "Checking Stripe CLI"
    if command -v stripe &>/dev/null; then
        info "Stripe CLI already installed"
        return
    fi

    if [[ "$OS" == "Darwin" ]]; then
        info "Installing Stripe CLI via brew..."
        brew install stripe/stripe-cli/stripe || warn "Stripe CLI install failed (non-fatal, install manually if needed)"
    else
        if [[ ${EUID:-$(id -u)} -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
            root_prefix="sudo "
        fi
        info "Installing Stripe CLI via apt..."
        curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public \
            | gpg --dearmor \
            | ${root_prefix}tee /usr/share/keyrings/stripe.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" \
            | ${root_prefix}tee /etc/apt/sources.list.d/stripe.list >/dev/null
        ${root_prefix}apt-get update -qq
        ${root_prefix}apt-get install -y stripe || warn "Stripe CLI install failed (non-fatal, install manually if needed)"
    fi

    success "Stripe CLI installed"
}

# ============================================================================
# Claude Code (official install script)
# ============================================================================

install_claude_code() {
    step "Checking Claude Code"
    if command -v claude &>/dev/null; then
        info "Claude Code already installed"
        return
    fi

    if ! command -v curl &>/dev/null; then
        warn "curl not found — skipping Claude Code install"
        return
    fi

    info "Installing Claude Code via official install script..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        success "Claude Code installed"
    else
        warn "Claude Code install failed (non-fatal, install manually if needed)"
    fi
}

# ============================================================================
# OpenAI Codex CLI (npm global)
# ============================================================================

install_codex() {
    step "Checking OpenAI Codex CLI"
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
# OpenCode (official install script)
# ============================================================================

install_opencode() {
    step "Checking OpenCode"
    if command -v opencode &>/dev/null || [[ -x "$HOME/.opencode/bin/opencode" ]]; then
        info "OpenCode already installed"
        return
    fi

    if ! command -v curl &>/dev/null; then
        warn "curl not found — skipping OpenCode install"
        return
    fi

    info "Installing OpenCode via official install script..."
    if curl -fsSL https://opencode.ai/install | bash; then
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
# Fonts
# ============================================================================

install_nerd_font() {
    local font_cask="font-meslo-lg-nerd-font"

    if [[ "$OS" != "Darwin" ]]; then
        warn "Nerd Font auto-install is only configured for macOS + Homebrew"
        return
    fi

    if ! command -v brew &>/dev/null; then
        warn "Homebrew not found - skipping Nerd Font install"
        return
    fi

    if brew list --cask "$font_cask" &>/dev/null; then
        info "Meslo Nerd Font already installed"
        return
    fi

    info "Installing Meslo Nerd Font..."
    if brew install --cask "$font_cask"; then
        success "Meslo Nerd Font installed"
    else
        warn "Meslo Nerd Font install failed (non-fatal, set up a Nerd Font manually)"
    fi
}

# ============================================================================
# Neovim config (jdhao/nvim-config)
# ============================================================================

setup_nvim() {
    local nvim_target="$HOME/.config/nvim"
    local nvim_locale="${LANG:-C.UTF-8}"

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
        if nvim_headless_runs_cleanly "lua require('lazy').sync({wait=true})" "$nvim_locale"; then
            success "nvim plugins installed"
        else
            warn "nvim plugin sync failed — check :Lazy in nvim for details"
            return 1
        fi

        if command -v tree-sitter &>/dev/null; then
            info "Pre-installing tree-sitter parsers..."
            if nvim_headless_runs_cleanly "lua local ts = require('nvim-treesitter'); ts.install('all'):wait()" "$nvim_locale"; then
                success "tree-sitter parsers installed"
            else
                warn "tree-sitter parser install failed — check :TSInstall in nvim for details"
                return 1
            fi
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
    symlink "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"
    symlink "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Ensure machine-local zsh override file exists
    [[ -f "$HOME/.zshrc.local" ]] || touch "$HOME/.zshrc.local"
}

setup_zsh_symlinks() {
    info "Creating zsh symlinks..."
    symlink "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
    symlink "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"
    symlink "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"

    [[ -f "$HOME/.zshrc.local" ]] || touch "$HOME/.zshrc.local"
}

setup_tmux_symlinks() {
    info "Creating tmux symlinks..."
    symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
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
    local zsh_path login_user root_prefix=""
    zsh_path="$(command -v zsh)"
    login_user="${USER:-$(id -un)}"

    if [[ -z "$zsh_path" ]]; then
        warn "zsh not found — skipping shell change"
        return
    fi

    local current_shell
    if [[ "$OS" == "Darwin" ]]; then
        current_shell=$(dscl . -read /Users/"$login_user" UserShell | awk '{print $2}')
    else
        current_shell=$(getent passwd "$login_user" | cut -d: -f7)
    fi

    if [[ "$current_shell" == *zsh* ]]; then
        info "zsh is already the default shell"
        return
    fi

    # Make sure our zsh is in /etc/shells
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        if [[ ${EUID:-$(id -u)} -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
            root_prefix="sudo "
        fi
        info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | ${root_prefix}tee -a /etc/shells >/dev/null
    fi

    if command -v chsh >/dev/null 2>&1; then
        info "Changing default shell to zsh..."
        if chsh -s "$zsh_path" "$login_user"; then
            success "Default shell set to zsh — log out and back in to take effect"
        else
            warn "Unable to change default shell automatically"
        fi
    else
        warn "chsh not available — skipping default shell change"
    fi
}

# ============================================================================
# Category runners
# ============================================================================

install_zsh_category() {
    section "Zsh and shell defaults"
    install_category_packages zsh git
    install_ohmyzsh
    install_zsh_plugins
    install_powerlevel10k
    install_nerd_font
    setup_zsh_symlinks
    set_default_shell
}

install_tmux_category() {
    section "Tmux terminal multiplexer"
    install_category_packages tmux
    setup_tmux_symlinks
}

install_neovim_category() {
    section "Neovim editor setup"
    install_category_packages neovim tree-sitter-cli
    setup_nvim
}

install_python_category() {
    section "Python via pyenv"
    install_category_packages pyenv
    install_python_env
}

install_node_category() {
    section "Node.js tooling"
    install_category_packages node
}

install_ai_category() {
    section "AI coding tools"
    install_category_packages node huggingface-cli
    install_claude_code
    install_codex
    install_opencode
}

install_terminal_category() {
    section "Terminal utilities"
    install_category_packages fzf bat eza ripgrep
    install_tap_packages teamookla/speedtest/speedtest
    install_stripe
}

install_developer_category() {
    section "Developer CLI tools"
    install_category_packages git gh jq kubectl scw
    install_tap_packages supabase/tap/supabase
    install_claude_settings
    ensure_git_identity
}

run_selected_categories() {
    local selected_csv category
    selected_csv="${1:-$INSTALLER_SELECTED}"

    if [[ -z "$selected_csv" ]]; then
        selected_csv="$(installer_all_categories_csv)"
    fi

    initialize_task_states "$selected_csv"
    render_execution_screen "$selected_csv"

    IFS=, read -r -a categories <<< "$selected_csv"
    for category in "${categories[@]}"; do
        mark_task_state "$category" running
        render_execution_screen "$selected_csv"

        if case "$category" in
            zsh) run_with_gum_spinner "Installing $(installer_category_label zsh)" install_zsh_category ;;
            tmux) run_with_gum_spinner "Installing $(installer_category_label tmux)" install_tmux_category ;;
            neovim) run_with_gum_spinner "Installing $(installer_category_label neovim)" install_neovim_category ;;
            python) run_with_gum_spinner "Installing $(installer_category_label python)" install_python_category ;;
            node) run_with_gum_spinner "Installing $(installer_category_label node)" install_node_category ;;
            ai) run_with_gum_spinner "Installing $(installer_category_label ai)" install_ai_category ;;
            terminal) run_with_gum_spinner "Installing $(installer_category_label terminal)" install_terminal_category ;;
            developer) run_with_gum_spinner "Installing $(installer_category_label developer)" install_developer_category ;;
            *) fail "Unknown category: $category" ;;
        esac; then
            mark_task_state "$category" done
        else
            mark_task_state "$category" failed
            render_execution_screen "$selected_csv"
            render_final_summary "$selected_csv"
            fail "Category install failed: $category"
        fi

        render_execution_screen "$selected_csv"
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    choose_default_mode

    if installer_has_interactive_terminal; then
        ensure_gum || true
    fi

    if [[ "$INSTALLER_MODE" == "menu" ]]; then
        show_existing_install_menu
    fi

    if [[ -z "$INSTALLER_THEME" ]]; then
        show_theme_picker
    else
        set_theme "$INSTALLER_THEME"
    fi

    set_theme "${INSTALLER_THEME:-opencode}"
    if installer_use_gum; then
        gum_show_welcome
    else
        render_header "dotfiles installer" "OS: $OS | Dotfiles: $DOTFILES_DIR"
        [[ -n "$INSTALLER_MODE" ]] && render_menu_row "-" "Mode" "$INSTALLER_MODE"
        [[ -n "$INSTALLER_THEME" ]] && render_menu_row "-" "Theme" "$INSTALLER_THEME"
        [[ -n "$INSTALLER_SELECTED" ]] && render_menu_row "-" "Select" "$INSTALLER_SELECTED"
        echo
    fi

    if [[ "$INSTALLER_MODE" == "wizard" || "$INSTALLER_MODE" == "reconfigure" ]]; then
        show_category_checklist
        echo
        show_review_screen
        echo
        gum_confirm_install || exit 0
    fi

    run_selected_categories "$INSTALLER_SELECTED"

    echo
    success "All done!"
    render_final_summary "$INSTALLER_SELECTED"
    if ! installer_use_gum; then
        summary \
            "Machine-specific config goes in ~/.zshrc.local" \
            "Run 'p10k configure' to customize your prompt" \
            "Open nvim and run :Lazy to check plugin status" \
            "Set your terminal font to MesloLGS Nerd Font (or another Nerd Font)"
    fi

    save_installer_state "$INSTALLER_THEME" "$INSTALLER_SELECTED" 0
}

load_installer_state
parse_args "$@"

if [[ -z "${INSTALLER_TEST_MODE:-}" ]]; then
    main "$@"
fi
