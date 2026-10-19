# Settings Tabs, Appearance Modes, and High-Contrast Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement top navigation tabs in Settings (General, Appearance, Shortcuts), add support for Automatic / Light / Dark appearance modes across the entire app, move HUD sizing to Appearance, and update the Scope Dropdown button with a high-contrast standard macOS pill design.

**Architecture:** Extend `AppSettings` with `appearanceMode` (Automatic, Light, Dark). Refactor `SettingsView` with a top segmented tab bar (`General`, `Appearance`, `Shortcuts`). Update `HUDView`'s Scope Dropdown with a standard high-contrast pill styling and dynamic theme adaptation for both light and dark modes.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-19-settings-tabs-and-appearance-modes-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No Xcode `@State` compiler macros; state managed via `ObservableObject` / `@Published`.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. Dropdown chevron contrast: visible and clear in both Dark and Light modes.
2. Window sizing sliders properly situated inside the Appearance tab.
3. Switching appearance mode updates HUD, Settings, and Keybinding Editor instantly.
4. Settings window remains compact, properly aligned, and clean across all three tabs.

---

### Task 1: Appearance Mode Data Model & Dynamic Window Theme Updating

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_appearance_mode.swift`

**Interfaces:**
- Produces: `enum ColorSchemeMode: String, CaseIterable, Identifiable`
- Produces: `AppSettings.appearanceMode: String`
- Produces: `AppSettings.applyAppearance(to window: NSWindow?)`

- [ ] **Step 1: Write test script `/tmp/test_appearance_mode.swift`**
Validate `ColorSchemeMode` enum parsing and `NSAppearance` resolution for `.automatic`, `.light`, and `.dark`.

- [ ] **Step 2: Run test script to verify failure / initial state**
Run: `swift /tmp/test_appearance_mode.swift`
Expected: Fails because type does not exist yet.

- [ ] **Step 3: Implement `ColorSchemeMode` and `AppSettings.appearanceMode` in `KeyHUD.swift`**
Add `ColorSchemeMode` enum, add `appearanceMode` `@Published` property to `AppSettings`, and implement `applyAppearance(to window: NSWindow?)`.

- [ ] **Step 4: Run test script to verify passing output**
Run: `swift /tmp/test_appearance_mode.swift`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add ColorSchemeMode and appearance mode settings"
```

---

### Task 2: Standard High-Contrast Scope Dropdown Pill Button

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Consumes: `AppSettings.shared.appearanceMode`, `accent`
- Produces: High-contrast Scope Dropdown pill in `HUDView`

- [ ] **Step 1: Update Scope Selector button styling in `HUDView`**
Wrap the Scope Menu label in a native rounded pill with:
  - Distinct background fill (`Color.white.opacity(0.12)` in dark mode, or system control fill).
  - High-contrast border stroke (`Color.white.opacity(0.24)`).
  - Standard double chevron `chevron.up.chevron.down` with bright white/accent foreground color.
  - Generous horizontal padding (10pt) and vertical padding (6pt) with rounded corners (7pt).

- [ ] **Step 2: Update HUD background and text colors to respect appearance mode**
Allow the HUD view, search bar, and column cards to gracefully display in light mode (frosted silver glass, dark text) or dark mode (deep translucent glass, white text).

- [ ] **Step 3: Build and test compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: PASS.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift
git commit -m "style: implement standard high-contrast Scope Dropdown pill button"
```

---

### Task 3: Top Navigation Tabs in Settings & Sizing Migration

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Produces: `SettingsTab` enum (`General`, `Appearance`, `Shortcuts`)
- Produces: Segmented tab bar in `SettingsView`

- [ ] **Step 1: Create `SettingsTab` enum and state in `SettingsView`**
Define `enum SettingsTab: String, CaseIterable, Identifiable`.
Add `selectedTab: SettingsTab` to `SettingsView` (or via `SearchState` / `AppSettings`).

- [ ] **Step 2: Layout the Top Tab Bar in `SettingsView`**
Add a segmented top tab selector with icons:
  - `gearshape` General
  - `paintbrush` Appearance
  - `command` Shortcuts & Tools

- [ ] **Step 3: Organize content across the tabs**
  - **General Tab**:
    - System Permissions card
    - Activation Trigger radio list
    - Command Hold Delay slider
    - Pin Mode toggle
  - **Appearance Tab**:
    - Appearance Mode picker (Automatic, Light, Dark)
    - Accent Theme picker circles
    - Window Size sliders (Horizontal & Vertical % of screen)
  - **Shortcuts Tab**:
    - Manage Keybindings... (opens Editor)
    - Open Shortcuts JSON...
    - Import File...
    - Auto-Detect Configs
  - Keep Reset Defaults and Done button in the footer across all tabs.

- [ ] **Step 4: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```
Verify the app launches cleanly with tabs in Settings, appearance switching works, and the HUD dropdown arrow is sharp and clear.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add top navigation tabs to Settings and appearance mode switcher"
```
