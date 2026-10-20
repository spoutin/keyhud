# Export Icon Color Fix & Settings Export Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Match the header Export icon color to the adjacent buttons (`Color.gray`) and add an Export Cheatsheet button to the Keybinding Editor toolbar in Settings.

**Architecture:** 
1. Fix `HUDView` header Export button styling: style the `Menu` label with `.foregroundColor(.gray)` and standard button paddings matching `square.and.pencil`.
2. Add an "Export Cheatsheet (Markdown)" button to `KeybindingEditorView` toolbar in Settings that exports the currently selected application's shortcuts to clipboard or file.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Header export icon matches the muted gray (`.gray`) color of adjacent toolbar icons (`square.and.pencil`).
2. Export menu in Settings (Keybinding Editor tab) exports the currently selected app's shortcuts accurately to clipboard or Documents.

---

### Task 1: Fix Header Export Icon Color & Add Settings Export Button

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Fix Header Export Icon Color in `HUDView`**
Ensure the `Menu` label is wrapped with `.foregroundColor(.gray)` and `PlainButtonStyle()` so it renders with identical opacity and hue as `square.and.pencil`.

- [ ] **Step 2: Add Export Action to Settings `KeybindingEditorView` Toolbar**
Add a Menu button in the `KeybindingEditorView` quick tools bar offering:
- `Copy Markdown to Clipboard`
- `Save to Documents (KeyHUD)`

- [ ] **Step 3: Build and verify with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift docs/
git commit -m "fix: match header export icon color and add export button to settings"
```
