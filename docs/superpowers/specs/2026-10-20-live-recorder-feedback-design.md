# Design Specification: Real-Time Live Keystroke Feedback During Shortcut Recording

## 1. Intent & Purpose
When a user clicks "Record" in the Keybinding Editor, they currently see a generic *"● Type shortcut..."* prompt until they press the final key combination. 
Adding **real-time live keystroke feedback** means:
- As soon as the user presses modifier keys (e.g. holding `⌘`, or `⌃⌥`, or `⇧⌘`), the recording badge immediately displays those active modifiers as colorful badges in real-time.
- If they release a modifier, it updates dynamically.
- When they press the final character key (e.g. `K`), the complete combination is committed immediately.

---

## 2. Interaction & Visual Model

### 2.1 State & Events
- In `EditorState`:
  - `@Published var recordingLiveModifiers: String = ""` (e.g. `"⌘"`, `"⌃⌥"`, `"⇧⌘"`, etc.)
- In `SettingsWindowController`:
  - Listen for `.flagsChanged` events:
    - If `EditorState.shared.isRecording`:
      - Extract active modifiers from `event.modifierFlags`.
      - Convert to token string: e.g. `⌃`, `⌥`, `⇧`, `⌘`.
      - Update `EditorState.shared.recordingLiveModifiers`.
  - When `.keyDown` fires:
    - Commits the combination via `handleRecordedKey`.
    - Resets `recordingLiveModifiers = ""`.

### 2.2 Visual Presentation in Active Recording Pill
When `isThisRowRecording` is true:
- If `state.recordingLiveModifiers.isEmpty`:
  - Show: `● Type shortcut...` with `x` cancel button.
- If `!state.recordingLiveModifiers.isEmpty`:
  - Show: Live tokenized badges for the active held modifiers (e.g. `[ ⌥ ] [ ⌘ ]`) followed by `...` with `x` cancel button.
  - Glowing red/accent border indicates active recording capture.

---

## 3. Goals
- Instant, 0ms latency visual feedback for held modifier keys.
- Accurate multi-modifier combination display.
- Cancel on `Esc` or clicking `x`.
