# Font Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make fresh dotfiles installs set up the required Nerd Font dependency more reliably and document the remaining manual terminal selection step.

**Architecture:** Add a small, idempotent `install_nerd_font` function to the shell installer, call it from `main`, and expose a test mode so a shell test can source the installer without executing the full install. Update the README so the font dependency is visible before users hit broken glyphs.

**Tech Stack:** Bash, Homebrew casks, Markdown

---

### Task 1: Add a failing installer test

**Files:**
- Create: `tests/install_fonts_test.sh`
- Modify: `install.sh`

**Step 1: Write the failing test**

Create `tests/install_fonts_test.sh` with checks that:
- source `install.sh` with a test-mode guard enabled;
- stub `brew`, `info`, `success`, and `warn` as needed;
- call `install_nerd_font` on Darwin and expect a Homebrew cask install for `font-meslo-lg-nerd-font`;
- call `install_nerd_font` on non-Darwin and expect a skip warning.

**Step 2: Run test to verify it fails**

Run: `bash tests/install_fonts_test.sh`
Expected: FAIL because `install_nerd_font` and/or installer test mode do not exist yet.

**Step 3: Write minimal implementation**

Add a guard so `main` only runs when `INSTALLER_TEST_MODE` is not set.

**Step 4: Run test to verify it still fails for the right reason**

Run: `bash tests/install_fonts_test.sh`
Expected: FAIL because `install_nerd_font` behavior is still missing.

**Step 5: Commit**

Do not commit unless explicitly requested by the user.

### Task 2: Implement font installation behavior

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Extend `tests/install_fonts_test.sh` expectations to cover:
- already-installed cask path;
- missing `brew` path;
- successful install path.

**Step 2: Run test to verify it fails**

Run: `bash tests/install_fonts_test.sh`
Expected: FAIL with missing or incorrect message/command assertions.

**Step 3: Write minimal implementation**

Implement `install_nerd_font()` that:
- returns early with an info message if the Meslo Nerd Font cask is already installed;
- installs `font-meslo-lg-nerd-font` on Darwin when `brew` exists;
- warns and skips on unsupported platforms or when `brew` is unavailable;
- never exits the installer on a font install failure.

**Step 4: Run test to verify it passes**

Run: `bash tests/install_fonts_test.sh`
Expected: PASS

**Step 5: Commit**

Do not commit unless explicitly requested by the user.

### Task 3: Wire the installer and update docs

**Files:**
- Modify: `install.sh`
- Modify: `README.md`

**Step 1: Write the failing test**

Add a simple assertion in `tests/install_fonts_test.sh` or a separate shell check that verifies `main` invokes `install_nerd_font` before final notes are printed.

**Step 2: Run test to verify it fails**

Run: `bash tests/install_fonts_test.sh`
Expected: FAIL because `main` does not call the new step yet.

**Step 3: Write minimal implementation**

Call `install_nerd_font` from `main` and update `README.md` install/post-install sections to explain:
- the repo expects a Nerd Font;
- the installer attempts Meslo Nerd Font on macOS;
- the user still needs to select the font in their terminal.

**Step 4: Run test to verify it passes**

Run: `bash tests/install_fonts_test.sh && bash -n install.sh`
Expected: PASS

**Step 5: Commit**

Do not commit unless explicitly requested by the user.
