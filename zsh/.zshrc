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

# ─── Editor ────────────────────────────────────────────────────
export EDITOR='nvim'

# ─── bat as man pager ──────────────────────────────────────────
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ─── eza aliases (replaces ls) ─────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza --icons --group-directories-first -la'
alias la='eza --icons --group-directories-first -a'
alias lt='eza --icons --group-directories-first --tree --level=2'

# ─── fzf defaults ──────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*"'
export FZF_DEFAULT_OPTS="
  --color=fg:#D8DEE9,bg:#2E3440,hl:#88C0D0
  --color=fg+:#ECEFF4,bg+:#434C5E,hl+:#8FBCBB
  --color=info:#EBCB8B,prompt:#81A1C1,pointer:#BF616A
  --color=marker:#A3BE8C,spinner:#B48EAD,header:#88C0D0
"

# ─── oh-my-posh prompt ────────────────────────────────────────
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.dotfiles/oh-my-posh/theme.omp.json)"
fi

# ─── Local overrides (machine-specific aliases, paths, etc.) ──
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
