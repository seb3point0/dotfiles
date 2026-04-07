# ─── Homebrew ──────────────────────────────────────────────────
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ─── pyenv ─────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &>/dev/null && eval "$(pyenv init --path)"

# ─── Additional paths ─────────────────────────────────────────
export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$GOPATH/bin:$PATH"
