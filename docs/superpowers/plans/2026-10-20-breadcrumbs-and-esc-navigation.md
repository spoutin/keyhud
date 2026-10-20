# Header Breadcrumbs & Esc-to-Go-Back Navigation Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement interactive breadcrumb trail in the HUD header and a hierarchical Esc-to-go-back navigation stack that pops levels until closing.

**Architecture:** Add `scopeHistory: [HUDScope]` in `SearchState` with `pushScope(_:)` and `popScope()`. Replace static header title with a breadcrumb trail (`parent` › `current`). Update both local event monitor in `HUDWindowController` and `SearchBarView.onEscape` to unwind state in order: clear query ➔ pop scope ➔ unpin/close HUD.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-breadcrumbs-and-esc-navigation-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.

## Review Focus
1. When user is in Ghostty sub-profile (e.g. Neovim) and presses Esc with empty search bar, it returns to Ghostty Main, and next Esc closes HUD.
2. Clicking any prior breadcrumb in the trail jumps directly back to that scope.
3. If search query is non-empty, first Esc clears query without popping scope.

---

### Task 1: Navigation Stack Engine & Esc Unwind Logic

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_navigation_stack.swift`

**Interfaces:**
- Produces: `SearchState.scopeHistory: [HUDScope]`
- Produces: `SearchState.pushScope(_:)`
- Produces: `SearchState.popScope() -> Bool`

- [ ] **Step 1: Write test script `/tmp/test_navigation_stack.swift`**
Validate navigation stack push/pop behavior.

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_navigation_stack.swift`

- [ ] **Step 3: Implement `scopeHistory` in `SearchState` and update Esc handling**
Update `HUDWindowController.show()` event monitor and `HUDView.onEscape`:
Check `query.isEmpty` ➔ `searchState.popScope()` ➔ `hide()`.

- [ ] **Step 4: Build with `build.sh` to verify compilation**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: implement navigation stack and hierarchical Esc-to-go-back flow"
```

---

### Task 2: Header Breadcrumb Trail UI & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Produces: Breadcrumb trail in `HUDView` header

- [ ] **Step 1: Implement Header Breadcrumb Trail in `HUDView`**
When `scopeHistory` has items, show preceding crumb buttons with chevron separators (`chevron.right`) leading up to the current active scope dropdown pill. Clicking any earlier crumb pops back to it.

- [ ] **Step 2: Update `TODO.md`**
Record the breadcrumbs and Esc navigation feature in `TODO.md`.

- [ ] **Step 3: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: implement header breadcrumb trail and complete TODO task"
```
