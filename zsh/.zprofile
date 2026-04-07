# ─── Homebrew ──────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ─── pyenv ─────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

# ─── Additional paths ─────────────────────────────────────────
export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$GOPATH/bin:$PATH"
