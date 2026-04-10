# ─── Shared config (aliases, env vars, fzf) ───────────────────
[ -f ~/.shrc ] && . ~/.shrc

# ─── Oh My Zsh ─────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  aliases
  fzf
  kubectl
  pyenv
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

source $ZSH/oh-my-zsh.sh

# ─── oh-my-posh prompt ────────────────────────────────────────
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.dotfiles/oh-my-posh/theme.omp.json)"
fi

# ─── Local overrides (machine-specific aliases, paths, etc.) ──
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
