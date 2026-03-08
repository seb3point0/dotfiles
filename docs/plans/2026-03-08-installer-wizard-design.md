# Installer Wizard Design

## Goal

Turn `install.sh` into a polished, category-driven terminal wizard for first-time setup and reruns, while preserving a safe non-interactive mode for automation.

## Product intent

- Human: someone bootstrapping or refreshing a dev machine from a terminal
- Primary task: choose the right bundles quickly, understand what will happen, then run setup with confidence
- Feel: deliberate, capable, terminal-native, and calm under reruns

## Recommended direction

Use a single `install.sh` entrypoint with mode-aware behavior instead of separate install and update scripts.

- First run opens a full interactive wizard
- Existing installs can use a short action menu or flags like `--update` and `--reconfigure`
- Non-interactive runs stay available through explicit flags

This keeps one implementation path, one TUI system, and one mental model.

## User flows

### First run

1. Welcome screen
2. Theme selection
3. Category checklist with everything preselected by default
4. Optional details view for each category
5. Git identity step if `git user.name` or `user.email` is missing
6. Review screen showing selected categories and included tools
7. Execution screen with live step state
8. Final summary with next actions

### Existing install

Running `./install.sh` on an already installed machine shows a compact menu:

- Update installed setup
- Reconfigure categories
- Exit

Flags bypass the menu:

- `--update`
- `--reconfigure`
- `--all`
- `--categories tmux,neovim,node`
- `--theme opencode`

## Category model

The wizard should present setup as bundles rather than raw package names.

- zsh and terminal setup
- tmux and related setup
- neovim and related setup
- python environment
- node environment
- AI coding utilities
- terminal utilities
- developer CLIs

Each category maps to:

- packages to install
- config files to link
- optional follow-up tasks

The details view should show the contents of a category before execution.

## Interface design

### Visual language

Intent: terminal-native, confident, and tactile without pretending to be a GUI app.

Palette:

- `Opencode`: cyan structure, green success, amber warnings, slate base
- `Amber`: warm amber and cream on dark brown-charcoal
- `Mono`: low-color grayscale fallback

Depth:

- borders-only
- no heavy boxes everywhere
- use contrast, spacing, and one active highlight to create structure

Surfaces:

- base terminal background
- one highlighted active row style
- muted inactive text for skipped or unavailable options

Typography:

- rely on terminal font
- use uppercase section labels sparingly
- align columns cleanly and avoid visual noise

Spacing:

- 2-space indentation
- one-line rows where possible
- breathing room between stages, not between every line

### Signature element

The core signature is a bundle checklist that can expand into a package preview and then collapse back into a clean execution plan. The installer should feel like it is building a plan with the user, not just streaming logs.

## Behavior and controls

### Wizard controls

- Arrow keys or `j`/`k` to move
- Space to toggle a category
- Enter to continue
- `d` to view category details
- `q` to quit safely

Fallback behavior:

- if terminal capabilities are limited, degrade to numbered prompts instead of failing

### Execution states

Each task row should show one state:

- pending
- running
- done
- skipped
- failed

The execution screen should keep context visible, showing the selected theme, selected categories, and current phase.

## Update behavior

There is no separate `update.sh`.

Instead:

- `install.sh --update` refreshes the repo and reruns selected or previously enabled categories
- `install.sh --reconfigure` launches the full category wizard again
- plain `install.sh` on an existing install shows the short action menu

This reuses the same TUI system and avoids drift.

## Configuration persistence

The installer should save lightweight machine-local state so reruns know what was previously selected.

Suggested file:

- `~/.dotfiles-install-state`

Stored values:

- selected categories
- chosen theme
- whether first-run flow has completed

This file should be safe to regenerate and easy to inspect.

## Error handling

- Missing dependencies should mark the affected step as failed or skipped with a short reason
- Non-interactive mode should never block on prompts
- Partial category failures should not abort unrelated categories unless the failed step is foundational
- Final summary should list failures and suggested manual follow-up commands

## Testing strategy

- Unit-like shell checks for argument parsing and state selection logic
- Syntax validation with `bash -n install.sh`
- Non-interactive smoke tests for `--all`, `--categories`, and `--update`
- Manual interaction verification for theme picker, checklist navigation, and review screen

## Open constraints

- Keep implementation bash-native; do not require `fzf`, `gum`, or other extra TUI dependencies
- Preserve `curl | bash` bootstrap behavior
- Maintain safe rerun behavior for already-installed tools
- Keep output readable over SSH and in tmux
