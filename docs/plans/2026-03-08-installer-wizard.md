# Installer Wizard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current linear installer with a polished, category-driven wizard for first-time installs and reruns, while preserving a non-interactive flag-based mode.

**Architecture:** Keep a single `install.sh` entrypoint and refactor it around explicit categories, persisted installer state, and a small bash-native TUI layer. Interactive runs use a themeable wizard with review and execution screens; non-interactive runs use flags that feed the same underlying category execution engine.

**Tech Stack:** Bash, git, tput, shell-based state files, existing installer functions

---

### Task 1: Define installer categories and selection state

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a shell-level verification target for category metadata lookups.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; installer_categories | grep -qx "tmux"'
```

**Step 2: Run test to verify it fails**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; installer_categories | grep -qx "tmux"'`
Expected: fail because category helpers do not exist yet.

**Step 3: Write minimal implementation**

Add category definitions and helper functions in `install.sh`, for example:

```bash
INSTALL_CATEGORIES=(zsh tmux neovim python node ai terminal developer)

installer_categories() {
    printf '%s\n' "${INSTALL_CATEGORIES[@]}"
}
```

Add labels and tool lists for each category.

**Step 4: Run test to verify it passes**

Run: `INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; installer_categories | grep -qx "tmux"'`
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer category model"
```

### Task 2: Add installer state persistence

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test for saving and reading installer state.

```bash
INSTALLER_TEST_MODE=1 HOME="$(mktemp -d)" bash -lc 'source ./install.sh; save_installer_state "opencode" "tmux,node"; load_installer_state; [[ "$INSTALLER_THEME" == "opencode" ]] && [[ "$INSTALLER_SELECTED" == "tmux,node" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because state functions do not exist yet.

**Step 3: Write minimal implementation**

Add:

```bash
INSTALLER_STATE_FILE="$HOME/.dotfiles-install-state"
save_installer_state() { ... }
load_installer_state() { ... }
```

Persist theme, selected categories, and first-run completion.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Persist installer wizard state"
```

### Task 3: Add argument parsing for install modes

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test for parsing `--update`, `--reconfigure`, `--theme`, and `--categories`.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; parse_args --update --theme opencode --categories tmux,node; [[ "$INSTALLER_MODE" == "update" ]] && [[ "$INSTALLER_THEME" == "opencode" ]] && [[ "$INSTALLER_SELECTED" == "tmux,node" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because parsing is not implemented.

**Step 3: Write minimal implementation**

Add a `parse_args()` function that recognizes:

```bash
--update
--reconfigure
--all
--theme <name>
--categories <csv>
```

Set internal mode and selection variables.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer mode parsing"
```

### Task 4: Build themeable TUI primitives

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test that theme setup exports expected color variables.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; set_theme opencode; [[ -n "$THEME_PRIMARY" && -n "$THEME_SUCCESS" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because theme support does not exist.

**Step 3: Write minimal implementation**

Add theme and rendering helpers:

```bash
set_theme() { ... }
render_header() { ... }
render_menu_row() { ... }
```

Support `opencode`, `amber`, and `mono`.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer theme system"
```

### Task 5: Implement first-run and rerun menus

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add tests for the menu decision logic.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; INSTALLER_FIRST_RUN=1; choose_default_mode; [[ "$INSTALLER_MODE" == "wizard" ]]'
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; INSTALLER_FIRST_RUN=0; choose_default_mode; [[ "$INSTALLER_MODE" == "menu" ]]'
```

**Step 2: Run test to verify it fails**

Run the commands above.
Expected: fail because the mode-selection logic does not exist.

**Step 3: Write minimal implementation**

Add functions for:

```bash
choose_default_mode()
show_existing_install_menu()
show_theme_picker()
```

Use numbered fallback prompts if advanced terminal input is unavailable.

**Step 4: Run test to verify it passes**

Run the commands above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer wizard entry flow"
```

### Task 6: Implement category checklist and review screen

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test for default category selection and category detail rendering.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; select_default_categories; [[ "$INSTALLER_SELECTED" == "zsh,tmux,neovim,python,node,ai,terminal,developer" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because category selection logic does not exist.

**Step 3: Write minimal implementation**

Add:

```bash
select_default_categories()
toggle_category()
show_category_details()
show_review_screen()
```

Default first-run selection should include all categories.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer category wizard"
```

### Task 7: Refactor execution into category-driven tasks

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test proving category execution dispatch calls the right setup functions.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; CALLED=(); install_tmux_category(){ CALLED+=(tmux); }; run_selected_categories "tmux"; [[ "${CALLED[*]}" == "tmux" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because dispatch does not exist.

**Step 3: Write minimal implementation**

Create category runner functions such as:

```bash
install_zsh_category() { ... }
install_tmux_category() { ... }
run_selected_categories() { ... }
```

Move the existing setup calls behind category runners.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Refactor installer into category runners"
```

### Task 8: Add execution progress screen and summaries

**Files:**
- Modify: `install.sh`
- Test: `install.sh`

**Step 1: Write the failing test**

Add a test for task state transitions.

```bash
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; mark_task_state tmux running; [[ "$(get_task_state tmux)" == "running" ]]'
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: fail because task-state tracking does not exist.

**Step 3: Write minimal implementation**

Add:

```bash
mark_task_state() { ... }
get_task_state() { ... }
render_execution_screen() { ... }
render_final_summary() { ... }
```

Track `pending`, `running`, `done`, `skipped`, `failed`.

**Step 4: Run test to verify it passes**

Run the command above.
Expected: pass.

**Step 5: Commit**

```bash
git add install.sh
git commit -m "Add installer execution dashboard"
```

### Task 9: Update docs for wizard, reruns, and flags

**Files:**
- Modify: `README.md`
- Test: `README.md`

**Step 1: Write the failing test**

Add a grep check for the new wizard and rerun flags.

```bash
rg -n "--update|--reconfigure|theme|categories" README.md
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: missing or incomplete matches.

**Step 3: Write minimal implementation**

Document:

```text
- first-run wizard flow
- rerun/update behavior
- category bundles
- theme choices
- non-interactive flags
```

**Step 4: Run test to verify it passes**

Run: `rg -n "--update|--reconfigure|theme|categories" README.md`
Expected: matches for the new installer docs.

**Step 5: Commit**

```bash
git add README.md
git commit -m "Document installer wizard flow"
```

### Task 10: Verify interactive and non-interactive paths

**Files:**
- Modify: none
- Test: `install.sh`

**Step 1: Write the failing test**

Prepare smoke tests for parser and shell validity.

**Step 2: Run test to verify it fails**

Run before implementation if needed:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; parse_args --all --theme mono; [[ "$INSTALLER_THEME" == "mono" ]]'
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; parse_args --update --categories tmux,node; [[ "$INSTALLER_MODE" == "update" ]]'
```

**Step 3: Write minimal implementation**

No additional code beyond previous tasks.

**Step 4: Run test to verify it passes**

Run:

```bash
bash -n install.sh
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; parse_args --all --theme mono; [[ "$INSTALLER_THEME" == "mono" ]]'
INSTALLER_TEST_MODE=1 bash -lc 'source ./install.sh; parse_args --update --categories tmux,node; [[ "$INSTALLER_MODE" == "update" ]]'
```

Expected: all commands pass.

**Step 5: Commit**

```bash
git add install.sh README.md
git commit -m "Verify installer wizard paths"
```
