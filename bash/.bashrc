# ─── Shared config (aliases, env vars, fzf) ───────────────────
[ -f ~/.shrc ] && . ~/.shrc

# ─── fzf key bindings (bash) ──────────────────────────────────
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.bash ] && . /opt/homebrew/opt/fzf/shell/key-bindings.bash

# ─── oh-my-posh prompt ────────────────────────────────────────
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  command -v oh-my-posh >/dev/null 2>&1 && \
    eval "$(oh-my-posh init bash --config ~/.dotfiles/oh-my-posh/theme.omp.json)"
fi

# ─── pyenv ─────────────────────────────────────────────────────
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

# ─── Local overrides ──────────────────────────────────────────
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
