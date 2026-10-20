# Design Specification: Multi-Key Sequence Accumulation & Mouse Click Confirmation

## 1. Intent & Purpose
In terminal tools, modal editors (Neovim/Vim, Lazygit), and CLI apps, key combinations often consist of multi-character sequences (e.g. `sgh`, `gd`, `ciw`, `<leader>ff`, `g?`) or chords containing special keys like `Return` (`↩`).
Using a keyboard key (like `Return`) to stop recording can cause collisions if `Return` is intended to be part of the recorded sequence.

Instead:
1. **Accumulate Sequences**: While recording, each keystroke (whether modified like `⌘K` or a raw character sequence like `s`, `g`, `h`) appends to the current sequence, rendering each token live.
2. **Finish via Mouse Click**: The recording pill displays a prominent green **"Done" (checkmark `✓`)** button. Clicking **Done** (or clicking anywhere outside) commits the recorded sequence.
3. **Cancel via Mouse Click**: A red **"Cancel" (`✕`)** button cancels recording without saving.
4. **Delete last key**: Clicking a backspace button (or hitting physical `⌫` Backspace) removes the last recorded character/token from the sequence.

---

## 2. Interaction & Visual Model

### 2.1 State in `EditorState`
- `@Published var recordingSequence: [String] = []`
- When recording begins: `recordingSequence.removeAll()`
- When a key event fires:
  - Extract the combo string (e.g. `"s"`, or `"g"`, or `"⌘K"`, or `"↩"`).
  - Append to `recordingSequence`: e.g. `["s", "g", "h"]`.
- The live pill renders:
  ```
  [ ● Recording: [ s ] [ g ] [ h ] ]  [ ✓ Done ]  [ ✕ Cancel ]
  ```
- Clicking **✓ Done**:
  - Joins `recordingSequence.joined(separator: "")` (or `" "` if chorded).
  - Updates the shortcut variant.
  - Exits recording mode.
- Clicking **✕ Cancel**:
  - Exits recording without saving.

---

## 3. Goals
- Enables recording arbitrary multi-key sequences (`sgh`, `ciw`, `gd`, etc.) and keys like `Return`, `Space`, `Tab`, `Esc`.
- Zero ambiguity: keyboard captures 100% of keystrokes; mouse click unambiguously stops recording.
