# Bootstrap Git and Brew Design

## Goal

Make first-run `curl | bash` bootstrap resilient on bare machines by ensuring Homebrew on macOS and Git on both macOS and Linux before the repo clone/pull step.

## Product intent

- Human: someone bootstrapping a fresh machine with minimal tooling installed
- Primary task: run one command and have the installer get itself into a usable state
- Feel: automatic, predictable, and low-friction

## Recommended direction

Add a tiny bootstrap layer at the top of `install.sh` that runs only in the pre-clone path.

- On macOS, always ensure Homebrew exists first, then ensure Git exists
- On Linux, ensure Git exists with the native package manager
- After those prerequisites are satisfied, continue with the existing clone/pull and re-exec flow

This keeps bootstrap logic minimal and separate from the larger installer wizard.

## Behavior

### macOS

1. Detect whether Homebrew is installed
2. If missing, install Homebrew via the official noninteractive curl command
3. Detect whether Git is installed
4. If missing, install Git via Homebrew
5. Continue to clone or pull the dotfiles repo

### Linux

1. Detect whether Git is installed
2. If missing, install it with the first supported native package manager found:
   - `apt`
   - `dnf`
   - `yum`
   - `apk`
   - `pacman`
   - `zypper`
3. Continue to clone or pull the dotfiles repo

## Constraints

- Keep the bootstrap logic small and shell-native
- Do not require Homebrew for Linux bootstrap
- Preserve the current in-repo installer flow after clone/re-exec
- Fail with a clear message if no supported Linux package manager is available

## Error handling

- If Homebrew install fails on macOS, exit with a clear error before clone
- If Git install fails on any platform, exit with a clear error before clone
- If Linux has no supported package manager, stop and print a manual Git install message

## Testing strategy

- Shell syntax check with `bash -n install.sh`
- Source-level test coverage for bootstrap helper dispatch in `INSTALLER_TEST_MODE`
- Function-level checks for:
  - macOS bootstrap choosing Homebrew path
  - Linux bootstrap choosing native package manager path
  - clone path calling bootstrap before Git operations
