# Bootstrap Git and Brew Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure first-run bootstrap installs Homebrew on macOS and Git on macOS/Linux before cloning or updating the dotfiles repo.

**Architecture:** Add a narrow bootstrap helper layer at the top of `install.sh` that runs only in the pre-clone path. Keep platform detection and package-manager logic isolated from the main installer wizard so the repo bootstrap stays simple and predictable.

**Tech Stack:** Bash, Homebrew install script, Linux native package managers, existing `install.sh` bootstrap flow

---

### Task 1: Add bootstrap Homebrew and Git helpers

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Use function-level checks in test mode for bootstrap helper presence and platform dispatch.

**Step 2: Run test to verify it fails**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type ensure_bootstrap_git >/dev/null 2>&1 && type ensure_bootstrap_brew >/dev/null 2>&1'`
Expected: fail because the helpers do not exist yet.

**Step 3: Write minimal implementation**

Add helpers such as:

```bash
ensure_bootstrap_brew() { ... }
ensure_bootstrap_git() { ... }
```

Behavior:
- macOS: install Homebrew if missing, then install Git if missing
- Linux: install Git with a supported native package manager if missing

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type ensure_bootstrap_git >/dev/null 2>&1 && type ensure_bootstrap_brew >/dev/null 2>&1'`
Expected: pass.

### Task 2: Wire bootstrap helpers into pre-clone flow

**Files:**
- Modify: `install.sh`

**Step 1: Write the failing test**

Verify the top bootstrap path calls the helper before Git operations.

**Step 2: Run test to verify it fails**

Run: `rg -n "ensure_bootstrap_git|ensure_bootstrap_brew|git clone|pull --ff-only" install.sh`
Expected before implementation: no bootstrap helpers in the pre-clone block.

**Step 3: Write minimal implementation**

In the `curl | bash` / pre-file path:

```bash
ensure_bootstrap_git
git clone ...
```

For macOS, `ensure_bootstrap_git` should ensure Homebrew first.

**Step 4: Run test to verify it passes**

Run: `rg -n "ensure_bootstrap_git|ensure_bootstrap_brew|git clone|pull --ff-only" install.sh`
Expected: bootstrap helpers appear before clone/pull logic.

### Task 3: Verify shell validity and bootstrap dispatch

**Files:**
- Modify: none

**Step 1: Write the failing test**

Prepare final syntax and dispatch checks.

**Step 2: Run test to verify it fails**

Run before implementation if needed:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type ensure_bootstrap_git >/dev/null 2>&1'
```

**Step 3: Write minimal implementation**

No extra code beyond Tasks 1 and 2.

**Step 4: Run test to verify it passes**

Run:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; type ensure_bootstrap_git >/dev/null 2>&1 && type ensure_bootstrap_brew >/dev/null 2>&1'
```

Expected: both commands pass.
