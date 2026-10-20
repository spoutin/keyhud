# Design Specification: Universal Command Palette Mode (Paletro-Style)

## 1. Intent & Purpose
Right now, `MenuScanner` extracts only menu bar items that have keyboard shortcuts assigned. Any menu command without a shortcut (e.g. *"Export As..."*, *"Clean Up By > Name"*, *"Format > Font > Strikethrough"*, *"Show Package Contents"*) is omitted.
In Paletro and IDE Command Palettes, users want to search and execute **any** menu bar action—whether it has a shortcut or not.

By adding a **Command Palette mode**:
1. `MenuScanner` indexes all clickable menu items (tracking breadcrumb paths like `File > Export > Export As PDF...`).
2. When an item has no keyboard shortcut, it shows a subtle `"Menu Action"` badge (or empty keys badge).
3. Clicking the row or pressing `Enter` performs `AXUIElementPerformAction(kAXPressAction)` on that menu item.
4. **Configurable in Settings & Togglable in the HUD**:
   - Setting in **Settings → General**:
     - `Show All Menu Actions (Command Palette Mode)`:
       - `Always` (shows in columns at all times)
       - `During Search Only` (default: keeps cheatsheet columns clean, but searches all actions when you type in the search bar)
       - `Shortcuts Only` (classic mode: ignores items without shortcuts)
   - Quick Toggle in HUD Header toolbar:
     - Command Palette icon (`command.circle` / `command`) to toggle all menu actions on/off in the active view on the fly!

---

## 2. Technical Architecture

### 2.1 MenuScanner Enhancements
Currently, `MenuScanner.extractShortcuts` has:
```swift
if let keys = formatShortcut(char: cmdChar, modifiers: modifiers) {
    items.append(ShortcutItem(title: title, keys: keys))
}
```
We update `MenuScanner` to support indexing all menu items:
- Each item retains its `AXUIElement` reference (already stored in `ActionExecutor.shared.cachedElements` or attached to `ShortcutItem`).
- If no shortcut keys exist, `keys` is `""`.
- Breadcrumb path prefixing: When nested in submenus (e.g. `View > Sort By > Name`), the title can display as `"Sort By > Name"`.

### 2.2 ShortcutRow Visual Representation for Action Items
When `item.keys.isEmpty`:
- In `ShortcutRow`, instead of an empty space or missing badge, render a subtle tag:
  `[ Action ]` or `[ ⏎ Execute ]` in secondary color with `Color.white.opacity(0.10)` background.
- When selected, highlighted with the accent color.
- Pressing `Enter` or clicking triggers `AXUIElementPerformAction(kAXPressAction)`.

### 2.3 Settings & Togglable State
1. In `AppSettings`:
   - `@Published var commandPaletteMode: String` (values: `"searchOnly"`, `"always"`, `"off"`)
2. In `SearchState`:
   - `@Published var isCommandPaletteActive: Bool = false`
3. In `HUDView`:
   - Top toolbar button: `command.square` / `command.circle` toggles `isCommandPaletteActive`.

---

## 3. Goals & Non-Goals
- **Goals**:
  - Instant fuzzy matching across every menu item of the frontmost app.
  - Zero regression on performance (<10ms).
  - Executable on click or `Enter`.
- **Non-Goals**:
  - Scanning disabled/grayed-out non-interactive static labels.
