# Gum Installer TUI Design

## Goal

Replace the current prompt-and-log installer interaction with a real `gum`-based terminal UI that feels closer to modern terminal tools like OpenCode and Claude.

## Product intent

- Human: someone setting up or reconfiguring a machine from the terminal
- Primary task: choose bundles quickly, understand what will happen, and run setup with confidence
- Feel: focused, styled, interactive, and clean rather than scroll-log driven

## Recommended direction

Use `gum` as the UI layer and keep bash as the installer runtime.

- `gum choose` for theme and mode selection
- `gum choose --no-limit` for category multi-select
- `gum style` for headers, cards, summaries, and warnings
- `gum confirm` for continue/review checkpoints
- `gum spin` for long-running install steps

This keeps the installer shell-native while making the interaction model much closer to the screenshot the user provided.

## User flows

### First run

1. Bootstrap clone/update
2. Ensure `gum` is available before entering the full installer UI
3. Theme selection
4. Category multi-select with checkboxes
5. Review card with selected bundles and included tools
6. Confirmation to start install
7. Step-by-step execution with spinner/progress output
8. Final summary card

### Existing install

1. Entry menu:
   - Update current setup
   - Reconfigure categories
   - Change theme only
   - Exit
2. If reconfigure, reopen the category multi-select UI
3. If update, run install with saved selections

## Interface design

### Visual language

- dark terminal canvas
- bold accent title line
- box/card layout for review sections
- one focused selection area at a time
- muted supporting text and bright active choices

### Theme mapping

Keep the existing logical themes but express them through `gum style` colors.

- `opencode`: cyan primary, bright white accent, green success, amber warning, gray muted
- `amber`: orange/amber primary, warm yellow accent, sand success, soft gray muted
- `mono`: white/gray only

### Signature element

The main signature is the category selection screen: a single clean checklist powered by `gum choose --no-limit`, followed by a boxed review of selected categories and bundled tools.

## Behavior

- When `gum` is available and stdin/stdout are interactive, use the gum UI path
- When `gum` is unavailable or the session is non-interactive, fall back to the plain shell path
- `curl | bash` bootstrap should still clone first, then re-exec into an interactive TTY-backed session so the gum UI can appear

## Linux package strategy

- Keep Linux package-manager first for core packages
- Still install Homebrew on Linux when a selected category needs brew-only tooling
- Do not make Linux wait on Homebrew for packages that are readily available through `apt`/native package managers

## Error handling

- If `gum` is missing on first run and the session is interactive, install it before the main UI if practical; otherwise warn and fall back
- Long-running actions should show a spinner and concise result, not dump logs unless something fails
- Failures should be summarized per category at the end

## Testing strategy

- shell syntax validation
- function-level tests for gum-path selection when `gum` is present
- function-level tests for fallback path when `gum` is absent
- fresh-container manual smoke test for first-run flow
