# shellcheck shell=bash
# Reads the palette from theme.omp.json — source this file, don't execute it.
# Usage: source ~/.dotfiles/oh-my-posh/palette.sh
eval "$(jq -r '.palette | to_entries[] | "export \(.key | ascii_upcase)=\"\(.value)\""' ~/.dotfiles/oh-my-posh/theme.omp.json)"
