#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        printf 'expected output to contain: %s\nactual: %s\n' "$needle" "$haystack" >&2
        return 1
    fi
}

run_case() {
    local os_name="$1"
    local brew_mode="$2"

    INSTALLER_TEST_MODE=1 \
    TEST_OS="$os_name" \
    TEST_BREW_MODE="$brew_mode" \
    bash <<'EOF'
set -euo pipefail

info() { printf 'INFO:%s\n' "$*"; }
success() { printf 'SUCCESS:%s\n' "$*"; }
warn() { printf 'WARN:%s\n' "$*"; }
fail() { printf 'FAIL:%s\n' "$*"; exit 1; }

uname() {
    printf '%s\n' "$TEST_OS"
}

command() {
    if [[ "$1" == "-v" && "$2" == "brew" ]]; then
        if [[ "$TEST_BREW_MODE" == "missing" ]]; then
            return 1
        fi
        printf '/opt/homebrew/bin/brew\n'
        return 0
    fi
    builtin command "$@"
}

brew() {
    case "$TEST_BREW_MODE" in
        installed)
            if [[ "$1" == "list" && "$2" == "--cask" && "$3" == "font-meslo-lg-nerd-font" ]]; then
                return 0
            fi
            ;;
        available|missing)
            if [[ "$1" == "list" && "$2" == "--cask" && "$3" == "font-meslo-lg-nerd-font" ]]; then
                return 1
            fi
            ;;
    esac
    printf 'BREW:%s\n' "$*"
}

source "$ROOT_DIR/install.sh"
install_nerd_font
EOF
}

darwin_output="$(run_case Darwin available)"
assert_contains "$darwin_output" 'BREW:install --cask font-meslo-lg-nerd-font'

linux_output="$(run_case Linux available)"
assert_contains "$linux_output" 'Nerd Font auto-install is only configured for macOS + Homebrew'

missing_brew_output="$(run_case Darwin missing)"
assert_contains "$missing_brew_output" 'Homebrew not found - skipping Nerd Font install'

installed_output="$(run_case Darwin installed)"
assert_contains "$installed_output" 'Meslo Nerd Font already installed'

printf 'install_fonts_test: PASS\n'
