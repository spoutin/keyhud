# Conflict Summary Banner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a high-visibility, interactive Conflict Summary Banner at the top of the Keybinding Editor that aggregates all internal and global collisions in one place.

**Architecture:**
- Add `allConflictSummaries()` in `EditorState` to aggregate colliding shortcuts and categories.
- Add `ConflictSummaryBannerView` in `KeyHUD.swift` displaying total counts, collapsible details list, and one-click conflict filtering.
- Place `ConflictSummaryBannerView` at the top of `KeybindingEditorView` just below the header toolbar.

**Tech Stack:** Swift, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-21-conflict-summary-banner-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros in `KeyHUD.swift`.

## Review Focus
1. When conflicts exist, the banner renders cleanly at the top of the editor with total count.
2. Clicking "Show Details / Hide Details" toggles the list of colliding pairs.
3. Clicking "Filter Conflicting Rows" enables the conflict filter.
4. When all conflicts are resolved or when 0 conflicts exist, the banner vanishes automatically.

---

### Task 1: Aggregated Conflict Model & Unit Tests

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_conflict_summary.swift`

**Interfaces:**
- Produces: `EditorState.allConflictSummaries() -> [ConflictSummaryItem]`

- [ ] **Step 1: Write standalone test script `/tmp/test_conflict_summary.swift`**
Validate conflict summary aggregation and pair formatting.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_conflict_summary.swift`

- [ ] **Step 3: Implement `allConflictSummaries()` in `EditorState`**
Add `ConflictSummaryItem` struct and extraction logic in `KeyHUD.swift`.

- [ ] **Step 4: Verify compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: ConflictSummaryBannerView in KeybindingEditorView

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Create `ConflictSummaryBannerView` in `KeyHUD.swift`**
Add interactive banner with warning header, details expander, and filter button.

- [ ] **Step 2: Place `ConflictSummaryBannerView` in `KeybindingEditorView`**
Add banner right below the toolbar.

- [ ] **Step 3: Update `TODO.md`**
Mark Conflict Summary Banner as completed.

- [ ] **Step 4: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: add interactive conflict summary banner to keybinding editor"
```
