# Design Specification: Settings Window ⌘W Close with Text Editing & Unsaved Changes Protection

## 1. Intent & Purpose
In macOS, users expect `⌘W` to close windows. However, in the Settings / Keybinding Editor window, two hazards exist:
1. **Accidental close while editing a keybinding**: If the user is typing in a "Keys" text field and types a shortcut that uses `⌘W` (e.g. for "Close Window"), the window must not close abruptly.
2. **Accidental loss of unsaved edits**: If the user presses `⌘W` or clicks the red window close button while `isDirty == true`, their work must not be discarded without confirmation.

---

## 2. Requirements & Interaction Model

### 2.1 First-Responder / Text Editing Guard
- When an `NSTextField` / `NSTextView` (or editor input) is the active first responder in the window and the user presses `⌘W`:
  - If the user is actively editing a "Keys" input or text field, the window does NOT close; the event is routed to the field or modifier input handler.
  - If no text input is being edited (e.g., standard window focus), `⌘W` initiates window closing.

### 2.2 Unsaved Changes Confirmation Dialog
- When a window close is initiated (via `⌘W` or the native window close button `windowShouldClose`):
  - **If `EditorState.shared.isDirty == false`**: The window closes immediately with zero prompts.
  - **If `EditorState.shared.isDirty == true`**: Display a native modal alert sheet attached to the settings window:
    - Title: *"Do you want to save your changes before closing?"*
    - Informative text: *"Your keybinding changes will be lost if you don't save them."*
    - Buttons:
      - **Save** (default button, `Return` key): calls `EditorState.shared.save()`, then closes the window.
      - **Don't Save** (`⌘D` or discard): reverts changes via `EditorState.shared.revert()`, then closes the window.
      - **Cancel** (`Esc` key): cancels closing; the window remains open and edits are preserved.

### 2.3 Window Delegate Hook
- Make `SettingsWindowController` conform to `NSWindowDelegate` and implement `windowShouldClose(_ sender: NSWindow) -> Bool`.
- Intercept local `keyDown` for `⌘W` on the settings window to verify first responder state before calling `window.performClose(nil)`.
