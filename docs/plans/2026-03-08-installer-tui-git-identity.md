# Installer TUI and Git Identity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve the dotfiles installer output so it feels more polished and prompt for missing global Git name/email during interactive installs.

**Architecture:** Keep the installer bash-native and rerunnable while adding lightweight presentation helpers for sections and status output. Add one focused interactive checkpoint for Git identity that only prompts when stdin is interactive and only when values are missing.

**Tech Stack:** Bash, git, Homebrew-based installer flow

---

### Task 1: Add installer UI helpers

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Identify that the installer only has basic `info`, `success`, `warn`, `fail` helpers and no section or summary helpers.

**Step 2: Run test to verify it fails**

Run: `rg -n "section\(|summary\(|step\(" install.sh`
Expected: no matches.

**Step 3: Write minimal implementation**

Add lightweight helpers such as:

```bash
section() { ... }
step() { ... }
```

Use them in key installer phases without changing install logic.

**Step 4: Run test to verify it passes**

Run: `rg -n "section\(|summary\(|step\(" install.sh`
Expected: matches for the new helper functions and calls.

### Task 2: Prompt for missing Git identity

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Identify that the installer does not check `git config --global user.name` or `user.email`.

**Step 2: Run test to verify it fails**

Run: `rg -n "user\.name|user\.email|ensure_git_identity" install.sh`
Expected before implementation: no relevant matches.

**Step 3: Write minimal implementation**

Add an `ensure_git_identity` function that:

```bash
local git_name git_email
git_name="$(git config --global --get user.name || true)"
git_email="$(git config --global --get user.email || true)"
```

Prompt only when stdin is interactive and a value is missing, then save with:

```bash
git config --global user.name "$git_name"
git config --global user.email "$git_email"
```

Warn and continue when non-interactive.

**Step 4: Run test to verify it passes**

Run: `rg -n "user\.name|user\.email|ensure_git_identity" install.sh`
Expected: matches for the check and prompt logic.

### Task 3: Verify installer remains valid

**Files:**
- Modify: none

**Step 1: Write the failing test**

Use shell syntax validation.

**Step 2: Run test to verify it fails**

Run before implementation if needed: `bash -n install.sh`

**Step 3: Write minimal implementation**

No extra code beyond Tasks 1 and 2.

**Step 4: Run test to verify it passes**

Run: `bash -n install.sh`
Expected: no output and exit code 0.
