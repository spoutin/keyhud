# Multi-Variant Alternate Shortcut Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow editing existing variants, adding new alternate variants (`+ Or`), and deleting individual variants in multi-keybinding shortcuts.

**Architecture:**
- Extend `EditorState` recording state with `recordingVariantIndex: Int?`.
- Split `keys` string by `" / "` into variants list.
- Provide `startRecordingVariant(category:index:variantIndex:)` and `addAlternateVariant(category:index:)`.
- In `handleRecordedKey`, replace or append the recorded combo into the variants list and join with `" / "`.
- Provide `deleteVariant(category:index:variantIndex:)` to remove a single alternate.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-multi-variant-shortcut-recorder-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. A shortcut with `⌘W / ⌘F4` renders as two separate pill groups separated by `/`.
2. Clicking Record on variant 0 updates only variant 0, preserving variant 1.
3. Clicking `+ Or` records and appends a second (or third) variant.
4. Clicking `x` on variant 1 deletes only variant 1.
5. All operations work cleanly with Undo (`⌘Z`).

---

### Task 1: Multi-Variant Recording Engine & Test

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_variant_recorder.swift`

**Interfaces:**
- Produces: `EditorState.startRecordingVariant(category:index:variantIndex:)`
- Produces: `EditorState.deleteVariant(category:index:variantIndex:)`
- Produces: `EditorState.handleRecordedKey(flags:keyCode:)` multi-variant support

- [ ] **Step 1: Write standalone test script `/tmp/test_variant_recorder.swift`**
Validate editing existing variant, adding alternate variant, and deleting single variant.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_variant_recorder.swift`

- [ ] **Step 3: Implement in `KeyHUD.swift`**
Update `EditorState` to support `recordingVariantIndex` and variant operations.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Multi-Variant UI in KeybindingEditorView

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Update Shortcut Row to Render Variants with Individual Controls**
ForEach variant in `currentKeys.split(separator: " / ")`:
- If actively recording this variant: show glowing `● Type shortcut...` with cancel button.
- If not: show token badges + re-record button + delete variant `x`.
- Plus `+ Or` button to append an alternate.

- [ ] **Step 2: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 3: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: support editing, adding, and removing multi-variant alternate shortcuts"
```
