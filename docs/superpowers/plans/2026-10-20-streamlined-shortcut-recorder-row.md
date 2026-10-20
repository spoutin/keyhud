# Streamlined Shortcut Row: Colored Badges & 1-Click Key Recorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Streamline shortcut rows in the Keybinding Editor by removing the manual "Keys" text box and modifier insertion buttons (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`). Replace them with a clean, native colored badge display and a dedicated "Record" button to capture shortcuts directly from the keyboard.

**Architecture:**
- Remove the "Keys" text field and all 6 manual modifier pill buttons from `KeybindingEditorView`.
- In each shortcut row:
  - Left: Title `TextField("Title", text: ...)` (spacious width: `260 pt`).
  - Middle: Live colored tokenized badge pills (`KeyTokenParser.parse`) or `"Record Shortcut"` button if empty.
  - Right:
    - If recording: glowing red pill (`● Type shortcut...`) with cancel button.
    - If idle: clean "Record" button (`record.circle`) to record new keys, plus clear ("x") and delete ("trash") buttons.
- Keystroke interception via `SettingsWindowController` local key monitor using `KeyComboDecoder`.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Carbon.

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. No manual text boxes or repetitive modifier buttons cluttering the shortcut row.
2. The colored key badges render identically to the HUD cheatsheet (`⌘` Blue, `⇧` Green, `⌥` Orange, `⌃` Purple, `⎋` Coral/Rose, `␣` Cyan).
3. Clicking "Record" displays *"● Type shortcut..."*; pressing any physical combination captures and formats it with colored badges immediately.
4. Bare `Esc` cancels recording; bare `Backspace` clears the shortcut to empty.
5. All recordings support `Undo` (`⌘Z`), `Save Changes` (`⌘S`), and `Revert`.

---

### Task 1: Replace Manual Keys Box with Colored Badge & Record Component

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Update Shortcut Row Layout in `KeybindingEditorView`**
Replace the "Keys" TextField and modifier buttons with:
- Title TextField
- Live colored badge pill view
- Record button (`record.circle`)
- Delete shortcut button (`trash` / `xmark.circle.fill`)

- [ ] **Step 2: Connect Keystroke Interceptor in `SettingsWindowController`**
In `SettingsWindowController` local key event monitor, when `EditorState.shared.isRecording`: route event to `EditorState.shared.handleRecordedKey(flags:keyCode:)`.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: replace manual keys text field and modifier pills with native colored badge recorder"
```
