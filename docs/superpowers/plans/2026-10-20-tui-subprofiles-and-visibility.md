# Shell & TUI Sub-Profiles and Main Visibility Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to organize terminal/TUI tools under Ghostty with per-category "Show on Main" visibility toggles in Settings, and provide a sub-menu in the HUD Scope dropdown to filter directly to any specific tool.

**Architecture:** Add `ghosttyHiddenCategories` in `AppSettings` to track categories excluded from the main view. Update `KeybindingEditorView` category headers to show a "Show on Main" toggle when editing Ghostty. Extend `HUDScope` with `.ghosttySubProfile(tool: String)` and populate the HUD scope dropdown menu accordingly.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-tui-subprofiles-and-visibility-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No third-party package dependencies.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. When a category has "Show on Main" toggled off, it must not appear on Ghostty's default main page, but MUST still be viewable via the sub-menu.
2. Toggling categories on/off updates live in the HUD without requiring an app relaunch.
3. Adding new categories under Ghostty preserves their visibility preferences properly.

---

### Task 1: Category Visibility Preferences & Editor Toggle Controls

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_tui_visibility.swift`

**Interfaces:**
- Produces: `AppSettings.ghosttyHiddenCategories: Set<String>`
- Produces: `AppSettings.isCategoryShownOnMain(name: String) -> Bool`
- Produces: `AppSettings.toggleCategoryOnMain(name: String)`

- [ ] **Step 1: Write test script `/tmp/test_tui_visibility.swift`**
Validate preference persistence and filtering logic.

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_tui_visibility.swift`

- [ ] **Step 3: Implement settings and category toggles in `KeyHUD.swift`**
Add `ghosttyHiddenCategories` to `AppSettings`.
In `KeybindingEditorView`, for `state.selectedBundleID == "com.mitchellh.ghostty"`, add a `Show on Main Cheatsheet` toggle switch in each category header.

- [ ] **Step 4: Build with `build.sh` to verify compilation**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add Ghostty category visibility controls in Keybinding Editor"
```

---

### Task 2: Ghostty Sub-Menu in HUD Header Scope Dropdown & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Consumes: `AppSettings.ghosttyHiddenCategories`
- Produces: `HUDScope.ghosttySubProfile(category: String)`
- Produces: Submenu options under Ghostty in the Scope Dropdown

- [ ] **Step 1: Update `HUDScope` and `currentScopeGroups` in `HUDView`**
Add `.ghosttySubProfile(category: String)` to `HUDScope`.
When `selectedScope == .activeApp` and the app is Ghostty, filter out categories in `ghosttyHiddenCategories`.
When `selectedScope == .ghosttySubProfile(let name)`, filter specifically to categories matching or prefixed with `name`.

- [ ] **Step 2: Add Ghostty sub-items in the Scope Dropdown Menu**
If the active app is Ghostty (or Ghostty config exists), render a sub-menu / section under Ghostty:
  - `Ghostty (Main)`
  - Sub-items for each configured tool category (`Neovim`, `Ghostty & Herdr`, `Zsh`, etc.) with matching icons (`terminal`, `chevron.left.forwardslash.chevron.right`, etc.).

- [ ] **Step 3: Update `TODO.md`**
Mark `Shell & TUI Application Cheatsheets with Ghostty Sub-Menu & Main Visibility Controls` as completed.

- [ ] **Step 4: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: implement Ghostty sub-menu in HUD scope dropdown and complete TODO task"
```
