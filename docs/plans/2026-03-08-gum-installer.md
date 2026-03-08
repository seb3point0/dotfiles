# Gum Installer TUI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the installer interaction layer around `gum` so first-run and rerun flows feel like a real terminal product instead of prompt-driven shell output.

**Architecture:** Keep `install.sh` as the entrypoint and execution engine, but route interactive sessions through `gum` UI helpers for menus, multi-select, confirmation, summary cards, and progress spinners. Preserve a shell fallback path for non-interactive runs and environments where `gum` is unavailable.

**Tech Stack:** Bash, `gum`, native package managers, Homebrew, existing installer category runners

---

### Task 1: Add gum detection and installation helpers

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type installer_has_gum >/dev/null 2>&1 && type ensure_gum >/dev/null 2>&1'`
Expected: fail because helpers do not exist yet.

**Step 2: Run test to verify it fails**

Run the command above.
Expected: non-zero.

**Step 3: Write minimal implementation**

Add helpers such as:

```bash
installer_has_gum() { ... }
ensure_gum() { ... }
```

Support installing `gum` via:
- Homebrew on macOS
- native package manager or Homebrew fallback on Linux

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type installer_has_gum >/dev/null 2>&1 && type ensure_gum >/dev/null 2>&1'`
Expected: pass.

### Task 2: Add gum-backed theme and menu selection

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_select_theme >/dev/null 2>&1 && type gum_select_existing_mode >/dev/null 2>&1'`
Expected: fail because gum selection helpers do not exist yet.

**Step 2: Run test to verify it fails**

Run the command above.
Expected: non-zero.

**Step 3: Write minimal implementation**

Add `gum` wrappers for:
- theme picker
- existing-install mode picker

Fallback to the current shell path when `gum` is unavailable.

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_select_theme >/dev/null 2>&1 && type gum_select_existing_mode >/dev/null 2>&1'`
Expected: pass.

### Task 3: Replace category checklist with gum multi-select

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_select_categories >/dev/null 2>&1'`
Expected: fail because the helper does not exist yet.

**Step 2: Run test to verify it fails**

Run the command above.
Expected: non-zero.

**Step 3: Write minimal implementation**

Add a `gum choose --no-limit`-based category selector that returns a CSV of selected categories and use it in `show_category_checklist` for interactive gum sessions.

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_select_categories >/dev/null 2>&1'`
Expected: pass.

### Task 4: Add gum review and confirmation screens

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_review_selection >/dev/null 2>&1 && type gum_confirm_install >/dev/null 2>&1'`
Expected: fail because the helpers do not exist yet.

**Step 2: Run test to verify it fails**

Run the command above.
Expected: non-zero.

**Step 3: Write minimal implementation**

Add:
- styled review card for selected categories and included tools
- confirmation step before install begins

Fallback to current review/continue behavior without `gum`.

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_review_selection >/dev/null 2>&1 && type gum_confirm_install >/dev/null 2>&1'`
Expected: pass.

### Task 5: Add gum progress wrappers for execution

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type run_with_gum_spinner >/dev/null 2>&1'`
Expected: fail because the spinner helper does not exist yet.

**Step 2: Run test to verify it fails**

Run the command above.
Expected: non-zero.

**Step 3: Write minimal implementation**

Wrap long-running category installs with `gum spin` where interactive gum is active, while preserving the current progress state tracking.

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type run_with_gum_spinner >/dev/null 2>&1'`
Expected: pass.

### Task 6: Keep Linux package-manager first and Homebrew supplemental

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; CALLED=(); install_brew(){ CALLED+=(brew); }; install_brew_packages(){ CALLED+=("brew:$*"); }; install_linux_packages(){ CALLED+=("linux:$*"); }; OS=Linux; install_tmux_category; [[ "${CALLED[*]}" == *"linux:tmux"* ]] && [[ "${CALLED[*]}" != *"brew:"* ]]'`
Expected before implementation: fail if Linux still routes core packages through brew first.

**Step 2: Run test to verify it fails**

Run the command above if needed.
Expected: non-zero before fix.

**Step 3: Write minimal implementation**

Preserve the Linux-first package logic and ensure `gum` install itself follows the same rule.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

### Task 7: Verify shell and interactive behavior

**Files:**
- Modify: none

**Step 1: Write the failing test**

Prepare final verification commands.

**Step 2: Run test to verify it fails**

Run before implementation if needed:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type gum_select_categories >/dev/null 2>&1'
```

**Step 3: Write minimal implementation**

No extra code beyond previous tasks.

**Step 4: Run test to verify it passes**

Run:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type installer_has_gum >/dev/null 2>&1 && type gum_select_categories >/dev/null 2>&1 && type gum_review_selection >/dev/null 2>&1 && type run_with_gum_spinner >/dev/null 2>&1'
```

Expected: both commands pass.
