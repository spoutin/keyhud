# Dynamic Shrink-to-Fit Window Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow the HUD window to shrink-to-fit its shortcuts content up to the user-configured size ceiling, with a clean minimum floor (520 × 360).

**Architecture:** Update `applyScreenPercentageFrame(groups:)` in `HUDWindowController` to calculate the required content dimensions based on column count and item counts, clamping between `[520, 360]` and `[maxCeilingWidth, maxCeilingHeight]`. Call frame adjustment both on initial show and when changing scope/sub-tools.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-shrink-to-fit-window-sizing-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. When viewing a small app or sub-tool (e.g. 1-2 columns, few items), the window shrinks tightly to fit rather than displaying huge empty grey boxes.
2. When viewing an app with many items/columns (e.g. Chrome or Ghostty Main), the window expands up to the user's configured percentage ceiling.
3. The window never shrinks smaller than the 520 × 360 minimum floor.
4. Settings labels clearly reflect "Max Width / Max Height" ceiling semantics.

---

### Task 1: Content Size Estimation & Window Fitting Engine

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_size_calculation.swift`

**Interfaces:**
- Produces: `HUDWindowController.calculateFittedFrame(screen:groups:) -> NSRect`
- Produces: Dynamic frame updates in `HUDWindowController.applyScreenPercentageFrame()`

- [ ] **Step 1: Write standalone test script `/tmp/test_size_calculation.swift`**
Validate fitting logic across 1-group (small), 3-group (medium), and 12-group (large) content.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_size_calculation.swift`

- [ ] **Step 3: Implement shrink-to-fit calculation in `HUDWindowController`**
Update `applyScreenPercentageFrame(groups: [ShortcutGroup] = [])` to compute `fittedWidth` and `fittedHeight` clamped between `[520, 360]` and `[maxCeilingWidth, maxCeilingHeight]`.

- [ ] **Step 4: Update Settings UI copy**
Update Settings appearance sliders to clearly state "Max Window Width" and "Max Window Height" (Ceiling).

- [ ] **Step 5: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 6: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: implement shrink-to-fit HUD window sizing with max ceiling"
```

---

### Task 2: Wire Dynamic Scope Resizing & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Wire resize on scope change**
When `searchState.selectedScope` changes, trigger smooth window frame adjustment to adapt to the new scope's content size.

- [ ] **Step 2: Update `TODO.md`**
Record the shrink-to-fit feature in `TODO.md`.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: wire dynamic scope resizing and complete TODO task"
```
