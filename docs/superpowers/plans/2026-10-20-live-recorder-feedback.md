# Real-Time Live Keystroke Feedback During Shortcut Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display held modifier badges in real-time as the user presses and holds keys during shortcut recording.

**Architecture:**
- Add `@Published var liveModifiers: String = ""` to `EditorState`.
- In `SettingsWindowController`, monitor `.flagsChanged` events when `isRecording` and update `EditorState.shared.liveModifiers`.
- In `KeybindingEditorView`, when recording, render live modifier badge pills if `!state.liveModifiers.isEmpty` instead of static "Type shortcut...".

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-live-recorder-feedback-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Pressing and holding `⌘` immediately renders `[ ⌘ ]` badge in the recording pill.
2. Adding `⇧` renders `[ ⇧ ] [ ⌘ ]`.
3. Releasing `⇧` updates back to `[ ⌘ ]`.
4. Pressing a key commits the combo and clears live modifiers.
5. Pressing bare `Esc` cancels recording and resets live modifiers.

---

### Task 1: FlagsChanged Monitor & Live Modifiers State

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_live_modifiers.swift`

**Interfaces:**
- Produces: `EditorState.liveModifiers: String`
- Produces: `EditorState.updateLiveModifiers(flags: NSEvent.ModifierFlags)`

- [ ] **Step 1: Write standalone test script `/tmp/test_live_modifiers.swift`**
Validate modifier flags formatting.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_live_modifiers.swift`

- [ ] **Step 3: Implement `updateLiveModifiers` in `EditorState`**
Add `liveModifiers: String` and `.flagsChanged` listener in `SettingsWindowController`.

- [ ] **Step 4: Update UI in `KeybindingEditorView`**
Display `KeyTokenParser.parse(state.liveModifiers)` badges live when `!state.liveModifiers.isEmpty`.

- [ ] **Step 5: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 6: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: show live held modifier badges in real-time during shortcut recording"
```
