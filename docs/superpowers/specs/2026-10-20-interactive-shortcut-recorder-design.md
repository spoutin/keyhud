# Design Specification: Interactive Shortcut Recorder in Keybinding Editor

## 1. Intent & Purpose
In the Keybinding Editor, users currently type modifier symbols (`⌃`, `⌥`, `⇧`, `⌘`) or click modifier insert pills manually into a text box.
A **Record Shortcut** component provides a fluid, native macOS experience: users click "Record", press any key combination directly on their physical keyboard (e.g. `⌘⇧K`, `⌃⌥Space`, `F12`, `⌘↩`), and KeyHUD immediately decodes, captures, formats, and updates the shortcut.

---

## 2. Requirements & Interaction Model

### 2.1 Visual Presentation
- In each shortcut row of `KeybindingEditorView`:
  - Beside the "Keys" field (or replacing the manual text field with an interactive recorder field):
    - When idle: displays the current shortcut string with a record button (`record.circle` icon or "Record").
    - When recording: displays a glowing blue/accent badge with *"Type shortcut..."* and a pulsing red recording dot.
    - An optional "×" clear button to clear the keybinding back to empty.

### 2.2 Keystroke Interception & Decoding
- When a row enters recording mode:
  - An `NSEvent` local event monitor intercepts `.keyDown`.
  - The event extracts:
    1. **Modifier Flags**: `.command` (`⌘`), `.shift` (`⇧`), `.option` (`⌥`), `.control` (`⌃`).
    2. **Key Glyph**:
       - Function keys (`F1` - `F20`).
       - Special keys: `Space`, `Esc`, `Tab`, `Return` (`↩`), `Delete` (`⌫`), `Up` (`↑`), `Down` (`↓`), `Left` (`←`), `Right` (`→`).
       - Standard ANSI characters: `A`-`Z`, `0`-`9`, punctuation.
  - If `Esc` is pressed with no modifiers: cancels recording mode without changing the shortcut.
  - If `Delete` / `Backspace` is pressed with no modifiers: clears the shortcut.
  - When a valid combination (modifiers + key, or special key) is pressed:
    - Formats the combo string (e.g. `⌃⌥⌘T`).
    - Calls `state.updateShortcut(...)` (which records undo and sets dirty state).
    - Exits recording mode.

---

## 3. Architecture
- `ShortcutRecorderView`:
  - Custom AppKit / SwiftUI view that listens for key events when active.
  - Emits `(String) -> Void` upon capture.
- `KeyHUD.KeyDecoder`:
  - Decodes `NSEvent` into standard KeyHUD formatted string (e.g. `⌃⇧⌘P`).
