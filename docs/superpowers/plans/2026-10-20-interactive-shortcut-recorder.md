# Interactive Shortcut Recorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to record physical key combinations directly in the Keybinding Editor by pressing keys on their keyboard.

**Architecture:** 
1. Build `KeyComboDecoder` to decode `NSEvent` (modifiers + keycode/characters) into KeyHUD canonical format (`⌃`, `⌥`, `⇧`, `⌘` + key).
2. Create `ShortcutRecorderField` component in `KeybindingEditorView`: displays a "Record" button or active "Type shortcut..." pill.
3. Hook recording state into `EditorState.updateShortcut` with undo stack support.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Carbon.

**Spec:** `docs/superpowers/specs/2026-10-20-interactive-shortcut-recorder-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Pressing `⌘⇧K` records as `⇧⌘K`.
2. Pressing special keys (`Space`, `Tab`, `Return`, `Esc`, `F1`-`F12`, `Arrow keys`) formats correctly.
3. Pressing bare `Esc` cancels recording without saving.
4. Pressing bare `Backspace` clears the shortcut to empty.
5. All recordings integrate cleanly with `Undo` (`⌘Z`) and dirty tracking.

---

### Task 1: KeyComboDecoder & Key Recorder Engine

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_key_decoder.swift`

**Interfaces:**
- Produces: `KeyComboDecoder.decode(event: NSEvent) -> String?`

- [ ] **Step 1: Write standalone test script `/tmp/test_key_decoder.swift`**
Validate decoding of key combinations, modifiers, and special keys.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_key_decoder.swift`

- [ ] **Step 3: Implement `KeyComboDecoder` in `KeyHUD.swift`**
Implement decoding logic mapping `NSEvent.modifierFlags` and `NSEvent.keyCode` / characters.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: ShortcutRecorderField UI & Integration

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Produces: `ShortcutRecorderField: View` in `KeybindingEditorView`

- [ ] **Step 1: Implement `ShortcutRecorderField`**
Create an interactive field displaying the current shortcut, a "Record" button (`record.circle`), and when active: a glowing "Type shortcut..." badge with a local key event monitor.

- [ ] **Step 2: Integrate into `KeybindingEditorView` shortcut rows**
Place `ShortcutRecorderField` alongside the manual "Keys" text field and quick-insert modifier pills, giving users both 1-click recording and manual editing.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: implement interactive shortcut recorder in keybinding editor"
```
