# Multi-Key Sequence Recorder with Mouse Click Confirmation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow recording multi-key sequences (e.g. `sgh`, `gd`, `ciw`) and special keys by accumulating strokes in real-time, finished by clicking a "✓ Done" button.

**Architecture:**
- Update `EditorState` to track `recordingTokens: [String]` instead of single combo.
- Append each struck key/combo into `recordingTokens`.
- Update `RecordingBadgeView` to show:
  - Active accumulated badges.
  - Live held modifier badges.
  - "✓ Done" button (green) -> commits sequence.
  - "✕ Cancel" button -> cancels recording.
  - "⌫" button -> removes the last token.
- `commitRecording()` saves the accumulated sequence into the shortcut variant.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-sequence-recorder-mouse-confirm-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Typing `s`, then `g`, then `h` accumulates `[ s ] [ g ] [ h ]` live in the recording pill.
2. Clicking "✓ Done" commits `"sgh"` as the shortcut.
3. Typing `Return` (`↩`), `Space`, or `Tab` records the key instead of exiting.
4. Clicking "✕ Cancel" cancels recording without saving.
5. All operations support `Undo` (`⌘Z`) and dirty state tracking.

---

### Task 1: Sequence Accumulation State & Tests

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_sequence_recorder.swift`

**Interfaces:**
- Produces: `EditorState.recordingTokens: [String]`
- Produces: `EditorState.appendRecordedStroke(token:)`
- Produces: `EditorState.commitRecording()`
- Produces: `EditorState.removeLastRecordedToken()`

- [ ] **Step 1: Write standalone test script `/tmp/test_sequence_recorder.swift`**
Validate sequence accumulation, backspace, and commit logic.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_sequence_recorder.swift`

- [ ] **Step 3: Implement sequence accumulation in `EditorState`**
Update `KeyHUD.swift` with `recordingTokens`, `appendRecordedStroke`, and `commitRecording`.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Mouse-Confirm Recording UI in RecordingBadgeView

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Update `RecordingBadgeView`**
Display accumulated tokens + live held modifiers + "✓ Done" button (green) + "⌫" undo stroke + "✕ Cancel" button.

- [ ] **Step 2: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 3: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: support multi-key sequences with mouse click confirmation"
```
