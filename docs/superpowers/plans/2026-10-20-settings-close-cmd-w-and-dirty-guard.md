# Settings Window ⌘W Close with Text Editing & Unsaved Changes Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `⌘W` window closing on Settings with active text editing protection and unsaved changes confirmation dialog.

**Architecture:** 
1. `SettingsWindowController` conforms to `NSWindowDelegate`.
2. Implement `windowShouldClose(_:)` to inspect `EditorState.shared.isDirty`. If clean, closes immediately. If dirty, displays native `NSAlert` modal sheet with Save, Don't Save, and Cancel.
3. Add local `NSEvent` key monitor in `SettingsWindowController` for `⌘W` that checks if first responder is an `NSTextView` (field editor). If actively editing a text field, ignores window close; otherwise calls `window.performClose(nil)`.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Pressing `⌘W` when on General or Appearance tabs closes the window immediately.
2. Pressing `⌘W` on Shortcuts tab when clean closes immediately with zero alerts.
3. Pressing `⌘W` when keybindings are modified (`isDirty == true`) presents a native alert sheet with Save, Don't Save, and Cancel.
4. Clicking the red window close button also triggers the unsaved changes sheet if dirty.
5. While focused and typing inside a shortcut text field, pressing `⌘W` does NOT close the window.

---

### Task 1: NSWindowDelegate & Unsaved Changes Alert Sheet

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Produces: `SettingsWindowController: NSWindowDelegate`
- Produces: `SettingsWindowController.windowShouldClose(_:) -> Bool`
- Produces: `SettingsWindowController.promptUnsavedChanges(completion:)`

- [ ] **Step 1: Implement `NSWindowDelegate` and `windowShouldClose`**
In `SettingsWindowController`, set `window.delegate = self`.
Implement `windowShouldClose(_ sender: NSWindow) -> Bool`:
If `!EditorState.shared.isDirty`, return `true`.
If `isDirty`, present `NSAlert` as a sheet:
- Button 1: "Save" -> `EditorState.shared.save()`; `window.close()`
- Button 2: "Cancel" -> do nothing
- Button 3: "Don't Save" -> `EditorState.shared.revert()`; `window.close()`
Return `false` while sheet is presented.

- [ ] **Step 2: Add `⌘W` Key Handler with First Responder Check**
In `SettingsWindowController`, listen for `⌘W` key events.
Check `window.firstResponder is NSTextView` (field editor):
- If user is editing a text field, do not close.
- Otherwise, call `window.performClose(nil)`.

- [ ] **Step 3: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "feat: implement Cmd+W close with text editing guard and unsaved changes confirmation sheet"
```
