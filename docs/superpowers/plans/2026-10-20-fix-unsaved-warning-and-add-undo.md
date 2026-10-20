# Fix Unsaved Changes Warning, Relocate to Frozen Row & Add Undo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 
1. Fix spurious "Unsaved Changes" warning by tying `isDirty` to `config != savedConfig` and establishing a clean baseline on reload.
2. Relocate "Unsaved Changes" badge to the far right of the frozen Quick Tools bar (beside Auto-Detect Configs).
3. Add an "Undo" button (with `⌘Z` shortcut) backed by an undo history stack in `EditorState`.

**Architecture:**
- `EditorState`:
  - `private var savedConfig: [String: [String: [[String: String]]]]`
  - `private var undoStack: [[String: [String: [[String: String]]]]]`
  - `var isDirty: Bool { config != savedConfig }`
  - `var canUndo: Bool { !undoStack.isEmpty }`
  - `recordUndo()` before mutations; `undo()` pops state.
- `shortcutsEditorTabView`:
  - Frozen row contains `Open JSON Config...`, `Import File...`, `Auto-Detect Configs`, `Spacer()`, and `Unsaved Changes` warning badge on the far right.
- `KeybindingEditorView`:
  - Top action bar includes `Undo` (`⌘Z`), `Revert`, `Save Changes` (`⌘S`).
  - Removed old "Unsaved Changes" from inside the scroll view.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. When opening Settings, "Unsaved Changes" is NEVER displayed initially if no changes were made.
2. Editing a shortcut, adding a category, or modifying keys shows the badge on the far right of the frozen Quick Tools row.
3. Clicking "Undo" (or pressing `⌘Z`) rolls back edits and disables when stack is empty.
4. If edits are undone back to the saved state, "Unsaved Changes" badge disappears.
5. All builds and tests pass.

---

### Task 1: Fix `EditorState` Dirty State & Undo History Stack

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_editor_undo.swift`

**Interfaces:**
- Produces: `EditorState.isDirty: Bool` (computed `config != savedConfig`)
- Produces: `EditorState.canUndo: Bool`
- Produces: `EditorState.undo()`
- Produces: `EditorState.recordUndo()`

- [ ] **Step 1: Write standalone test script `/tmp/test_editor_undo.swift`**
Validate `recordUndo()`, `undo()`, `canUndo`, and `isDirty` when modifying and undoing.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_editor_undo.swift`

- [ ] **Step 3: Implement in `KeyHUD.swift`**
Update `EditorState` with `undoStack`, `recordUndo()`, `undo()`, `savedConfig`, and computed `isDirty`.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Relocate Warning Badge to Frozen Row & Add Undo Button to UI

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Add "Undo" button to `KeybindingEditorView` action bar**
Place `Button("Undo")` beside `Revert` and `Save Changes`, bound to `state.undo()`, disabled when `!state.canUndo`, with keyboard shortcut `⌘Z`.

- [ ] **Step 2: Move "Unsaved Changes" badge to the frozen Quick Tools row**
In `shortcutsEditorTabView`: place the warning badge on the far right after `Spacer()`. Remove the old warning from inside the scroll view in `KeybindingEditorView`.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "fix: resolve unsaved changes warning, move to frozen row, and add undo support"
```
