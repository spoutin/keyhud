# Per-Application Keybinding Viewer & Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS Keybinding Editor window to inspect, add, edit, and delete application shortcuts inline, with multi-point access from both Settings and the floating HUD cheatsheet.

**Architecture:** An `EditorState` observable document model loads and stages edits to `custom_shortcuts.json` without modifying disk until saved. The SwiftUI/AppKit `KeybindingEditorWindowController` provides an application dropdown, collapsible category cards, inline editable title/key rows, and quick-insert modifier pills (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`). `HUDWindowController` is updated to merge custom shortcuts alongside native scanned menu bar items for standard macOS apps while keeping terminal layouts isolated.

**Tech Stack:** Pure Swift 6, AppKit, SwiftUI, compiled via `swiftc` into `/Applications/KeyHUD.app`.

**Spec:** `/Users/ablack/.config/keyhud/docs/superpowers/specs/2026-10-19-keybinding-editor-design.md`

## Global Constraints
- Language & Runtime: Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `build.sh`.
- No third-party dependencies, no Xcode `@State` compiler macros; state managed via `ObservableObject` / `@Published`.
- File Storage: `~/.config/keyhud/custom_shortcuts.json`.
- Changes must immediately sync to active HUD instances on save.

## Review Focus
- Switching applications in the dropdown with unsaved edits must preserve in-memory changes across apps until saved or reverted.
- Creating an empty shortcut or category must not crash JSON serialization or HUD parsing.
- Merging custom shortcuts with native menu items must not break click-to-execute (`AXUIElement` actions for menu items, `CGEvent` synthesis for custom shortcuts).
- Inserting modifier pills must append valid chord symbols (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`) compatible with `ActionExecutor`.
- Opening the editor from the HUD header must automatically select the active application in the dropdown.

---

### Task 1: Data Model Extensions & Shortcut Merging

**Files:**
- Modify: `KeyHUD.swift`
- Test: Verification script via `swift -`

**Interfaces:**
- Consumes: `CustomShortcutsManager.shared`, `MenuScanner.scan(app:)`
- Produces: `CustomShortcutsManager.allAppBundleIDs() -> [String]`, `HUDWindowController.resolveGroups(for:) -> [ShortcutGroup]`

- [ ] **Step 1: Write verification script to test shortcut merging logic**

```bash
swift - << 'EOF'
import Foundation

// Verify dictionary manipulation and bundle ID extraction
var config: [String: [String: [[String: String]]]] = [
    "com.mitchellh.ghostty": ["Ghostty": [["title": "Palette", "keys": "⇧⌘P"]]],
    "com.apple.Safari": ["Custom Navigation": [["title": "Next Tab", "keys": "⌃Tab"]]]
]
assert(config.keys.sorted().contains("com.apple.Safari"))
print("Data model test passed")
EOF
```

- [ ] **Step 2: Run verification script**

Run: `swift - << 'EOF' ... EOF`
Expected: PASS with "Data model test passed"

- [ ] **Step 3: Update `CustomShortcutsManager` and `HUDWindowController` in `KeyHUD.swift`**

- Add helper `allAppBundleIDs() -> [String]` in `CustomShortcutsManager` returning sorted keys.
- Update `HUDWindowController.show(for:)` so for `com.mitchellh.ghostty`, custom shortcuts are used exclusively, while for any other app with custom groups, custom groups are merged with `MenuScanner.scan(app:)`.

- [ ] **Step 4: Verify compilation via `build.sh`**

Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: Successful compilation and code-signing.

- [ ] **Step 5: Commit**

```bash
cd /Users/ablack/.config/keyhud
git add KeyHUD.swift
git commit -m "feat: add app bundle querying and custom-with-menu shortcut merging"
```

---

### Task 2: Editor State Model & Modifier Helper

**Files:**
- Modify: `KeyHUD.swift`

**Interfaces:**
- Consumes: `CustomShortcutsManager.shared.loadConfig()`
- Produces: `class EditorState: ObservableObject`, `addShortcut(category:)`, `deleteShortcut(category:index:)`, `addCategory(name:)`, `deleteCategory(name:)`, `insertModifier(_:category:index:)`, `save()`, `revert()`

- [ ] **Step 1: Write test script verifying `EditorState` mutations**

```bash
swift - << 'EOF'
// Verify in-memory state manipulation
var mockConfig: [String: [String: [[String: String]]]] = [
    "com.apple.Safari": ["General": [["title": "Test", "keys": "⌘T"]]]
]
mockConfig["com.apple.Safari"]?["General"]?.append(["title": "New", "keys": "⌘N"])
assert(mockConfig["com.apple.Safari"]?["General"]?.count == 2)
print("EditorState test passed")
EOF
```

- [ ] **Step 2: Run test script to verify**

Run: `swift - << 'EOF' ... EOF`
Expected: PASS with "EditorState test passed"

- [ ] **Step 3: Implement `EditorState` in `KeyHUD.swift`**

- Implement `@Published var config`, `@Published var selectedBundleID`, `@Published var isDirty`.
- Implement CRUD operations for categories and shortcuts.
- Implement modifier insertion helper appending `⌃`, `⌥`, `⇧`, `⌘`, `Space`, or `Esc` to the key field.
- Implement `save()` writing to `CustomShortcutsManager.shared.saveConfig(...)`.

- [ ] **Step 4: Verify compilation via `build.sh`**

Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: Successful compilation.

- [ ] **Step 5: Commit**

```bash
cd /Users/ablack/.config/keyhud
git add KeyHUD.swift
git commit -m "feat: implement EditorState model for document-level shortcut management"
```

---

### Task 3: Keybinding Editor Window & SwiftUI View

**Files:**
- Modify: `KeyHUD.swift`

**Interfaces:**
- Consumes: `EditorState`
- Produces: `struct KeybindingEditorView: View`, `class KeybindingEditorWindowController: NSWindowController`

- [ ] **Step 1: Write compilation test for `KeybindingEditorView`**

```bash
swift - << 'EOF'
import Cocoa
import SwiftUI
print("KeybindingEditorView interface ready")
EOF
```

- [ ] **Step 2: Implement `KeybindingEditorView` and `KeybindingEditorWindowController` in `KeyHUD.swift`**

- App dropdown selector in header with option to add new application bundle ID.
- Category cards with title, delete category, and list of shortcut rows.
- Shortcut rows with editable Title, editable Keys, modifier pill buttons, and delete button.
- "+ Add Shortcut" button per category.
- Header buttons for "Save Changes" (highlighted when dirty) and "Revert".
- Dedicated resizable `NSWindow` (720x580, min 550x420) centered on screen.

- [ ] **Step 3: Verify build via `build.sh`**

Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: Successful compilation and code-signing.

- [ ] **Step 4: Commit**

```bash
cd /Users/ablack/.config/keyhud
git add KeyHUD.swift
git commit -m "feat: build KeybindingEditorView and KeybindingEditorWindowController"
```

---

### Task 4: Multi-Point Access & UI Integration

**Files:**
- Modify: `KeyHUD.swift`

**Interfaces:**
- Consumes: `KeybindingEditorWindowController.shared.openEditor(bundleID:)`
- Produces:
  1. Edit button (`Image(systemName: "square.and.pencil")`) in `HUDView` header.
  2. "Manage Keybindings..." button in `SettingsView`.
  3. "Edit Keybindings..." menu item in `AppDelegate` status menu.

- [ ] **Step 1: Wire up all 3 access points in `KeyHUD.swift`**

- In `HUDView`: Add edit button in top header next to Pin button, calling `KeybindingEditorWindowController.shared.openEditor(bundleID: activeBundleID)`.
- In `SettingsView`: Add "Manage Keybindings..." button under SHORTCUTS & CONFIGURATIONS.
- In `AppDelegate`: Add "Edit Keybindings..." item in `NSMenu`.

- [ ] **Step 2: Test building the app**

Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: Done! KeyHUD installed to /Applications/KeyHUD.app.

- [ ] **Step 3: Commit**

```bash
cd /Users/ablack/.config/keyhud
git add KeyHUD.swift
git commit -m "feat: wire Keybinding Editor access into HUD header, Settings, and menu tray"
```

---

### Task 5: End-to-End Verification & Roadmap Update

**Files:**
- Modify: `TODO.md`

- [ ] **Step 1: Launch `/Applications/KeyHUD.app`**

Run: `open /Applications/KeyHUD.app`
Expected: Running process with PID.

- [ ] **Step 2: Verify Keybinding Editor opens and edits persist**

Verify `custom_shortcuts.json` remains valid JSON and can be read/written by the app.

- [ ] **Step 3: Update `TODO.md`**

Mark "Per-Application Keybinding Viewer & Editor" complete in `TODO.md`.

- [ ] **Step 4: Commit final changes**

```bash
cd /Users/ablack/.config/keyhud
git add TODO.md
git commit -m "docs: mark Per-Application Keybinding Viewer & Editor complete in TODO.md"
```
