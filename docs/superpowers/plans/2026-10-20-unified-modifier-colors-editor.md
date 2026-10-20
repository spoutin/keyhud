# Unified Modifier Colors & Icon Scheme in Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the modifier colors, glyph styling, live token badge previews, and legend bar across the Keybinding Editor tab in Settings.

**Architecture:** Create reusable `ModifierPillButton` using `KeyTokenParser` color palette, integrate a real-time `KeyTokenParser` preview in each editor shortcut row, and attach `modifierLegendItems` at the bottom of the editor view.

**Tech Stack:** Swift 6, SwiftUI, AppKit.

**Spec:** `docs/superpowers/specs/2026-10-20-unified-modifier-colors-editor-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No Xcode `@State` compiler macros; state managed via `ObservableObject` / `@Published`.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. Color mapping between HUD pills and editor pills must be 100% identical.
2. Space (`␣ Space`) and Esc (`⎋ Esc`) buttons must cleanly insert the glyph or token.
3. Live badge preview updates reactively as the user types or clicks insertion pills.
4. Legend bar fits cleanly at the bottom without clipping editor scrolling.

---

### Task 1: Styled Modifier Quick-Insert Pills & Live Token Preview

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_modifier_pills.swift`

**Interfaces:**
- Produces: `ModifierPillButton` component
- Consumes: `KeyTokenParser`, `EditorState`

- [ ] **Step 1: Write test script `/tmp/test_modifier_pills.swift`**
Validate token parsing and color styling for editor modifier keys (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`).

- [ ] **Step 2: Run test script to verify failure / initial state**
Run: `swift /tmp/test_modifier_pills.swift`
Expected: PASS/verify.

- [ ] **Step 3: Implement `ModifierPillButton` and live token preview in `KeyHUD.swift`**
Replace plain buttons in `KeybindingEditorView` with vibrant pills (`⌃` Purple, `⌥` Orange, `⇧` Green, `⌘` Blue, `␣ Space` Cyan, `⎋ Esc` Coral). Add live `HStack` preview beside the `Keys` TextField.

- [ ] **Step 4: Build with `build.sh` to verify compilation**
Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add vibrant modifier quick-insert pills and live token preview in Keybinding Editor"
```

---

### Task 2: Embed Modifier Legend Bar & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Consumes: `modifierLegendItems`
- Produces: Footer legend bar in `KeybindingEditorView`

- [ ] **Step 1: Add bottom modifier legend bar to `KeybindingEditorView`**
Add the reference legend bar at the bottom of the Keybinding Editor tab matching the HUD footer.

- [ ] **Step 2: Update `TODO.md`**
Mark the item under `Unified Modifier Colors & Icon Scheme in Settings & Keybinding Editor` as complete.

- [ ] **Step 3: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md
git commit -m "feat: add modifier legend bar to Keybinding Editor and complete TODO task"
```
