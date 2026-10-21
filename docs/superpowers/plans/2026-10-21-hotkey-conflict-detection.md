# Hotkey Conflict Detection (Internal & Global) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement proactive internal and global hotkey conflict detection with live recorder feedback, editor warning badges, HUD indicator badges, and a one-click conflict audit filter.

**Architecture:**
- Create `ShortcutNormalizer` to canonicalize shortcuts (order modifiers `⌃⌥⇧⌘`, lowercase keys).
- Create `ShortcutConflictDetector` to detect internal duplicates and collisions with AeroSpace, macOS System, and KeyHUD.
- Add real-time collision detection inside `RecordingBadgeView`.
- Add conflict warning badges to shortcut rows in `KeybindingEditorView` and `ShortcutRow` in the HUD.
- Add a "Show Conflicts (N)" filter button in `KeybindingEditorView`.

**Tech Stack:** Swift, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-21-hotkey-conflict-detection-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros in `KeyHUD.swift`.

## Review Focus
1. Assigning the same shortcut to two commands in the same app marks both with an internal conflict badge.
2. A shortcut matching AeroSpace (e.g. `⌥H`) or macOS System (e.g. `⌘Space`) marks the row with a global collision badge.
3. While recording, typing a colliding combination displays a live warning banner in the recording pill.
4. Clicking "Show Conflicts" in the editor toolbar filters the view to only conflicting shortcuts.
5. In the HUD, conflicting shortcuts display a subtle warning icon with an explanatory hover tooltip.

---

### Task 1: Shortcut Normalization & Conflict Detector Engine with Unit Tests

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_conflict_detector.swift`

**Interfaces:**
- Produces: `ShortcutNormalizer.canonical(combo:) -> String`
- Produces: `ShortcutConflictDetector.detectConflicts(...) -> [ConflictInfo]`

- [ ] **Step 1: Write standalone test script `/tmp/test_conflict_detector.swift`**
Validate canonicalization (e.g. `⇧⌘P` == `⌘⇧P`), internal duplicate matching, and global conflict matching.

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_conflict_detector.swift`

- [ ] **Step 3: Implement `ShortcutNormalizer` and `ShortcutConflictDetector` in `KeyHUD.swift`**
Add canonical formatting and conflict evaluation logic.

- [ ] **Step 4: Verify compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Live Recording Conflict Warnings & Editor Badges

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Add live conflict check in `RecordingBadgeView`**
When `recordingSequence` matches an existing shortcut in the current app or global scope, display an inline warning pill: `⚠️ Conflict with: [Title]`.

- [ ] **Step 2: Add conflict badges to shortcut rows in `KeybindingEditorView`**
Show ⚠️ `Conflict: [Other Title]` or ⚡ `Global: [AeroSpace/System Name]` beside the variant badges.

- [ ] **Step 3: Add "Show Conflicts (N)" filter toggle button in `KeybindingEditorView`**
Filter categories and items when active so users can audit and resolve all conflicts quickly.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 3: HUD Warning Badges & Roadmap Update

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Update `ShortcutRow` in HUD**
Display a subtle warning triangle `exclamationmark.triangle.fill` on conflicting items with an explanatory hover tooltip.

- [ ] **Step 2: Update `TODO.md`**
Add and check off the Hotkey Conflict Detection feature.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: internal and global hotkey conflict detection with live recorder warnings"
```
