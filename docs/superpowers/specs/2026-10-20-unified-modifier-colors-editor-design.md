# Design Specification: Unified Modifier Colors & Icon Scheme in Settings & Keybinding Editor

## 1. Intent & Purpose

Users need visual parity and instant recognition between the main HUD cheatsheet and the Keybinding Editor inside Settings. Currently, the Keybinding Editor shows plain text input fields and standard gray modifier buttons, whereas the HUD utilizes vibrant, distinctly colored tokenized pills (`⌘` Blue, `⇧` Green, `⌥` Orange, `⌃` Purple, `⎋` Coral/Rose, `␣` Cyan).

This specification unifies the visual language by:
1. Updating modifier insertion pills with dedicated glyphs and colors matching the HUD.
2. Rendering a real-time tokenized badge preview next to each shortcut key field in the editor.
3. Adding the modifier legend bar at the bottom of the Keybinding Editor tab in Settings.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Modifier Quick-Insert Pills**:
  - Replace the plain gray buttons (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`) with vibrant styled pills matching `KeyTokenParser`:
    - `⌘` Command: Vibrant Sky Blue with colored tint background & border.
    - `⇧` Shift: Emerald Green with colored tint background & border.
    - `⌥` Option: Warm Amber / Orange with colored tint background & border.
    - `⌃` Control: Mauve / Purple with colored tint background & border.
    - `␣ Space`: Cyan / Teal with colored tint background & border.
    - `⎋ Esc`: Coral / Rose Red with colored tint background & border.
- **Live Visual Token Preview in Shortcut Rows**:
  - Beside each shortcut's keys input field, render a live tokenized preview using `KeyTokenParser.parse(currentKeys)` showing the exact badge pills that will appear in the HUD cheatsheet.
- **Modifier Legend Bar**:
  - Embed the standard `modifierLegendItems` reference bar at the bottom of the editor tab for fast modifier lookup.
- **Support Light and Dark Themes**:
  - Ensure pills and token badges have crisp contrast in both Dark and Light appearance modes.

### Non-Goals
- Changing the underlying serialization format in `custom_shortcuts.json` (keys continue to store standard strings like `⇧⌘P` or `⌃S -`).

### Anti-Goals
- Cluttering the row with preview pills that overlap or crowd out the Title and Key text fields.

---

## 3. Architecture & Visual Components

### Modifier Button Component
A reusable view `ModifierPillButton`:
```swift
struct ModifierPillButton: View {
    let glyph: String
    let label: String
    let color: Color
    let action: () -> Void
    // Styled with matching tint and border
}
```

### Live Badge Preview
```swift
HStack(spacing: 3) {
    let tokens = KeyTokenParser.parse(currentKeys)
    ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
        Text(token.text)
            .font(.system(size: token.isSpecial ? 10 : 9, weight: .bold, design: .monospaced))
            .padding(.horizontal, token.isSpecial ? 4 : 3)
            .padding(.vertical, 1)
            .foregroundColor(token.color)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(token.color.opacity(0.18))
            )
    }
}
```
