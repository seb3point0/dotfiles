# Font Install Design

**Problem:** Fresh installs get zsh and tmux configs that require Nerd Font glyphs, but the installer does not install any font or surface the requirement early enough.

**Decision:** Update the installer to auto-install `font-meslo-lg-nerd-font` on macOS via Homebrew cask when Homebrew is available, skip gracefully on unsupported platforms, and keep a clear reminder that the user must still select the font in their terminal emulator.

**Scope:**
- Add a dedicated font installation step to `install.sh`.
- Keep the step non-fatal and idempotent.
- Move the font requirement higher in `README.md` and clarify first-run expectations.

**Non-goals:**
- Auto-configuring iTerm2, Terminal.app, Ghostty, Kitty, or any other terminal emulator.
- Installing fonts on every Linux distribution.

**Why this approach:**
- It fixes the missing dependency on the most common supported path in this repo: macOS + Homebrew.
- It preserves `curl | bash` friendliness by avoiding interactive prompts.
- It avoids brittle terminal-specific automation while still making the manual final step obvious.

**Verification:**
- Add a small shell test that sources `install.sh` in test mode and verifies the new font-install logic emits the expected commands/messages.
- Run the shell test and `bash -n install.sh`.
