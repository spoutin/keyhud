# Design Specification: Hide Known Shortcuts & Columns

## 1. Intent & Purpose
In almost every Mac and terminal app, users already know 30-50% of the basic shortcuts by heart (`⌘C`, `⌘V`, `⌘Z`, `⌘Q`, `⌘W`, or basic columns like `Help` or `Apple/Application`).
Displaying these clutters the HUD cheatsheet and forces users to scan through items they don't need.
Allowing users to hide entire categories/columns or individual shortcut commands from the Keybinding Editor dramatically reduces visual noise and surfaces only the shortcuts they actually want to learn.

---

## 2. Architecture & Data Model

### 2.1 Hidden Items Storage
We track hidden items persistently in `HiddenItemsManager`:
- Key: `"hiddenItemsByApp"` in `UserDefaults.standard`
- Shape: `[bundleID: [categoryName: Set<shortcutTitle>]]`
- Category-level hiding: When a category itself is hidden, it is added to a special set or dictionary: `"hiddenCategoriesByApp"`, shape `[bundleID: Set<categoryName>]`.
- Fast lookup methods:
  - `isCategoryHidden(bundleID: String, category: String) -> Bool`
  - `toggleCategoryHidden(bundleID: String, category: String)`
  - `isItemHidden(bundleID: String, category: String, title: String) -> Bool`
  - `toggleItemHidden(bundleID: String, category: String, title: String)`

### 2.2 Keybinding Editor UI
In `KeybindingEditorView`:
1. **Category Headers**:
   - Next to the Category name and `trash` button, add an Eye button:
     - If hidden: `Image(systemName: "eye.slash")` with `.foregroundColor(.secondary)`
     - If visible: `Image(systemName: "eye")` with subtle hover opacity.
     - Tooltip: `"Hide category from HUD"` / `"Unhide category"`
2. **Shortcut Rows**:
   - Next to the Re-record button and trash button, add an Eye button:
     - If hidden: `Image(systemName: "eye.slash")` (dimmed row title, strikethrough or secondary color)
     - If visible: `Image(systemName: "eye")` with subtle opacity on hover.
     - Tooltip: `"Hide shortcut from HUD"` / `"Unhide shortcut"`

### 2.3 HUD Filtering & Quick Peek
In `HUDViewModel` / `HUDView`:
- By default, `currentScopeGroups` filters out:
  - Any category where `HiddenItemsManager.shared.isCategoryHidden(bundleID, category)` is `true`.
  - Any shortcut item where `HiddenItemsManager.shared.isItemHidden(bundleID, category, title)` is `true`.
- In HUD Header toolbar:
  - Add an Eye button (`eye` / `eye.slash`) next to the Pin button:
    - `"Show Hidden (N)"` / `"Hide Known"`
    - When enabled, shows hidden items with a subtle muted opacity and strikethrough, allowing instant quick-peeking without having to open Settings.

---

## 3. Goals & Non-Goals
- **Goals**:
  - Full persistence across app launches in `UserDefaults`.
  - Seamless integration with both native apps and custom TUI shortcuts.
  - Zero performance impact on HUD open latency.
  - Reactive updates: toggling hide in Settings or HUD immediately updates the HUD view.
- **Non-Goals**:
  - Deleting user shortcuts: hiding is non-destructive and fully reversible at any time.
