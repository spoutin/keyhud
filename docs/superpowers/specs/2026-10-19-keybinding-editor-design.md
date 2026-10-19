# Design Specification: Per-Application Keybinding Viewer & Editor

## 1. Intent & Purpose

Users need a straightforward way to view, create, edit, and organize custom keybindings across multiple applications without manually hand-editing `~/.config/keyhud/custom_shortcuts.json`. The Keybinding Editor provides a native macOS UI accessible from both KeyHUD Settings and the floating HUD cheatsheet itself, allowing users to modify shortcut titles, key chords, and categories inline.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Multi-Point Access**: Accessible via:
  1. A "Manage Keybindings..." button in Settings.
  2. An edit icon (`square.and.pencil`) in the floating HUD header.
  3. A menu bar item ("Edit Keybindings...").
- **Application Dropdown**: Top header dropdown listing all configured apps (e.g. `com.mitchellh.ghostty`, `global`, etc.) with an option to add a new application by Bundle ID or running app picker.
- **Category & Shortcut Management**:
  - View all shortcut categories for the selected application.
  - Add and delete shortcut categories.
  - Add and delete individual shortcuts within any category.
- **Inline Editing**:
  - Title text field editable inline.
  - Keys combo field editable inline.
  - Quick-insert modifier buttons (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`) for easily inputting special Mac key glyphs.
- **Instant Persistence & HUD Sync**:
  - Changes save directly to `~/.config/keyhud/custom_shortcuts.json`.
  - The live HUD reloads its cache immediately upon saving so edits take effect without restarting the app.

### Non-Goals
- Real-time global OS hotkey remapping (KeyHUD visualizes and executes shortcuts; it does not replace third-party system keyboard remappers like Karabiner-Elements).
- Complex macro scripting beyond sequential keystroke chords.

### Anti-Goals
- Modal dialog lockouts: editing shortcuts should not lock the user into nested sub-dialogs; all changes should be editable inline within the window.
- Corrupting or overriding local configs auto-detected from Zsh/Herdr/Neovim unexpectedly.

---

## 3. Constraints & Architecture
- **Language & Runtime**: Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `build.sh` (no third-party dependencies, no Xcode `@State` compiler macros; state managed via `ObservableObject` / `@Published`).
- **File Storage**: `~/.config/keyhud/custom_shortcuts.json`.
- **Packaging**: Maintained within `/Applications/KeyHUD.app`.

---

## 4. User Experience & Layout Decisions

### Window Structure (`KeybindingEditorWindowController`)
- Dedicated resizable `NSWindow` (default size: 700x560, min size: 550x400) titled "KeyHUD Keybinding Editor".
- Header controls:
  - App selector dropdown: Pick existing apps or "+ Add New Application...".
  - "+ Add Category" button.
  - "Save Changes" and "Revert" action buttons.
- Body scroll view:
  - Lists categories in distinct collapsible cards or rounded panels.
  - Category header with title and "Delete Category" button.
  - List of shortcuts:
    - Title field (`NSTextField` / SwiftUI `TextField`).
    - Key Chord field.
    - Modifier glyph toolbar (`⌃` Control, `⌥` Option, `⇧` Shift, `⌘` Command, `⎋` Esc, `␣` Space).
    - Trash / Delete shortcut button.
  - "+ Add Shortcut" button at the bottom of each category card.

---

## 5. Technical Details for Implementation

1. **State Management (`EditorState: ObservableObject`)**:
   - Holds working copy of `[String: [String: [[String: String]]]]` loaded from `CustomShortcutsManager`.
   - `selectedBundleID: String`.
   - `isDirty: Bool` tracking unsaved edits.
   - `save()` method that writes back to `CustomShortcutsManager.shared.saveConfig(...)` and invalidates caches.

2. **Integration with Floating HUD**:
   - Add edit button (`Image(systemName: "square.and.pencil")`) in `HUDView` header between the Pin button and the Close button.
   - Clicking it calls `KeybindingEditorWindowController.shared.openEditor(bundleID: targetAppBundleID)`.

3. **Integration with Settings**:
   - Add "Manage Keybindings..." button under "SHORTCUTS & CONFIGURATIONS" in `SettingsView`.

4. **Modifier Insertion Helper**:
   - Clicking modifier pill appends or toggles the glyph in the active key combo string.
