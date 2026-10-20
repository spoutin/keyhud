# Hide Known Shortcuts & Columns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to hide entire categories (columns) and individual shortcut commands from the Keybinding Editor and quickly toggle hidden items in the HUD.

**Architecture:**
- Create `HiddenItemsManager` to persist hidden categories and shortcuts in `UserDefaults`.
- Update `KeybindingEditorView` to add `eye` / `eye.slash` toggle buttons to category headers and shortcut rows.
- Update `HUDView` / `HUDViewModel` to filter out hidden categories and hidden items by default, with a header Eye toggle to reveal hidden items when desired.

**Tech Stack:** Swift, SwiftUI, AppKit.

**Spec:** `docs/superpowers/specs/2026-10-20-hide-known-shortcuts-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros in `KeyHUD.swift`.

## Review Focus
1. Toggling eye on a category hides that entire column in the HUD.
2. Toggling eye on a shortcut row hides that individual shortcut from its column in the HUD.
3. Hiding is persistent across app launches in `UserDefaults`.
4. Header Eye button in the HUD reveals hidden items with a muted/dimmed appearance for quick peeking.
5. All operations update reactively without requiring an app relaunch.

---

### Task 1: Persistent Hidden Items Model & Unit Tests

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_hidden_items.swift`

**Interfaces:**
- Produces: `HiddenItemsManager.shared`
  - `isCategoryHidden(bundleID:category:) -> Bool`
  - `toggleCategoryHidden(bundleID:category:)`
  - `isItemHidden(bundleID:category:title:) -> Bool`
  - `toggleItemHidden(bundleID:category:title:)`

- [ ] **Step 1: Write standalone test script `/tmp/test_hidden_items.swift`**
Validate persistence and toggle behavior for categories and items.

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_hidden_items.swift`

- [ ] **Step 3: Implement `HiddenItemsManager` in `KeyHUD.swift`**
Create `HiddenItemsManager` as an `ObservableObject`.

- [ ] **Step 4: Verify compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Eye Controls in Keybinding Editor

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Add Category-Level Eye Toggle Button**
In `KeybindingEditorView`, beside the category trash button:
```swift
Button(action: {
    HiddenItemsManager.shared.toggleCategoryHidden(bundleID: state.selectedBundleID, category: category)
}) {
    Image(systemName: HiddenItemsManager.shared.isCategoryHidden(bundleID: state.selectedBundleID, category: category) ? "eye.slash.fill" : "eye")
        .foregroundColor(HiddenItemsManager.shared.isCategoryHidden(bundleID: state.selectedBundleID, category: category) ? Color.orange : Color.secondary)
}
.buttonStyle(PlainButtonStyle())
.help("Toggle visibility in HUD")
```

- [ ] **Step 2: Add Shortcut-Level Eye Toggle Button**
In each shortcut row in `KeybindingEditorView`:
```swift
Button(action: {
    HiddenItemsManager.shared.toggleItemHidden(bundleID: state.selectedBundleID, category: category, title: title)
}) {
    Image(systemName: isHidden ? "eye.slash.fill" : "eye")
        .foregroundColor(isHidden ? Color.orange : Color.secondary.opacity(0.6))
}
.buttonStyle(PlainButtonStyle())
.help(isHidden ? "Unhide shortcut in HUD" : "Hide shortcut in HUD")
```

- [ ] **Step 3: Verify compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 3: HUD Filtering & Header Quick Peek Toggle

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Add `showHiddenItems: Bool` to `HUDViewModel` / `SearchState`**
Allows toggling visibility of hidden shortcuts in the HUD.

- [ ] **Step 2: Filter out hidden categories and hidden items in `currentScopeGroups`**
Unless `showHiddenItems` is enabled, prune hidden categories and hidden items.

- [ ] **Step 3: Add Eye Button to HUD Header Toolbar**
Beside Pin button:
```swift
Button(action: { searchState.showHiddenItems.toggle() }) {
    Image(systemName: searchState.showHiddenItems ? "eye.fill" : "eye.slash")
        .foregroundColor(searchState.showHiddenItems ? accent : .gray)
}
.help(searchState.showHiddenItems ? "Hide known shortcuts" : "Show hidden shortcuts")
```

- [ ] **Step 4: Update `TODO.md`**
Mark `- [x] Hide Known / Muscle-Memory Shortcuts` as complete.

- [ ] **Step 5: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 6: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: hide known shortcuts and columns with editor toggles and HUD filter"
```
