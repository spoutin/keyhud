# Design Specification: Multi-Variant Alternate Shortcut Recording

## 1. Intent & Purpose
Many applications and CLI/TUI tools support alternate shortcuts for the same command (e.g. `⌘W / ⌘F4`, or `⌃D / PageDown`, or `j / ↓`), which KeyHUD renders with a clean `/` separator between variants.

When configuring keybindings in the Keybinding Editor, users need to:
1. **Edit an existing variant**: Clicking or recording a specific variant updates *just that variant* without affecting the others.
2. **Add a new alternate variant**: An `+ Or` / `+ Add` button allows recording an additional alternate (appended with ` / `).
3. **Delete an individual variant**: Each variant badge has its own subtle clear/delete button (`xmark`) to remove just that alternate.
4. **Re-record when empty**: If a shortcut has no keys at all, it shows a single "Record" button to establish the first variant.

---

## 2. Interaction Model & Data Flow

### 2.1 String Format
In `custom_shortcuts.json`, variants are stored as slash-separated tokens:
`"keys": "⌘W / ⌘F4"`
- Parsing: `keys.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }`
- Joining: `variants.joined(separator: " / ")`

### 2.2 Recording State
Instead of just `(category: String, index: Int)`, recording targets an optional `variantIndex: Int`:
- `recordingCategory: String?`
- `recordingIndex: Int?`
- `recordingVariantIndex: Int?` (e.g. `0` for primary, `1` for second variant, or `nil` when appending a new alternate)

When recording completes:
- If `recordingVariantIndex < variants.count`: replaces `variants[variantIndex]` with the new key combo.
- If `recordingVariantIndex == nil` (or appending): appends the new key combo: `variants.append(newCombo)`.
- Re-joins with `" / "` and calls `updateShortcut`.

### 2.3 Visual Representation per Row
For a shortcut with `keys = "⌃D / ↓"`:
```
[ Title Field ___________________________ ]
  [ ⌃ D ] (edit) (x)  /  [ ↓ ] (edit) (x)  [ + Or ]   [ 🗑️ ]
```
- Each variant displays its colored token badges.
- Clicking on a variant badge or its record icon enters recording mode for that specific variant (`● Type shortcut...`).
- An `+ Or` button adds a new alternate variant.
- Clicking `x` on a variant removes only that alternate.
- Clicking the trash can deletes the whole shortcut row.

---

## 3. Goals
- 100% mouse and keyboard-friendly.
- Zero manual typing required, even for multiple alternates.
- Retains undo stack and unsaved changes tracking.
