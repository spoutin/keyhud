# Scope Switcher & Global Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Scope Dropdown in the HUD header allowing users to toggle between viewing the Active Application, AeroSpace Tiling shortcuts, and macOS System Globals, each with dedicated icons and functional categories.

**Architecture:** Introduce `HUDScope` and `ScopeManager` to load shortcuts by scope. Create `AeroSpaceConfigParser` to parse `~/.config/aerospace/aerospace.toml` into clean categories, and `MacOSGlobalShortcuts` for system-wide shortcuts. Update `HUDView` header to render a scope dropdown menu with icons and dynamically rebind the shortcut column grid.

**Tech Stack:** Swift 6, AppKit, SwiftUI, TOML parsing logic.

**Spec:** `docs/superpowers/specs/2026-10-19-scope-switcher-and-global-shortcuts-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No third-party package dependencies.
- Keep terminal output formatting strictly compliant with Plain-text arithmetic (no LaTeX math).
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. AeroSpace config file missing or malformed: fallback gracefully without crashing.
2. Keystroke conversion: parse chords like `alt-shift-h`, `ctrl-1`, `alt-slash` into standard KeyHUD tokens (`⌥⇧H`, `⌃1`, `⌥/`).
3. Switching scopes should preserve search state and not dismiss the HUD.
4. Clicking or pressing Enter on a global shortcut should execute it cleanly.
5. Menu icons must render crisply in dark mode for macOS and AeroSpace.

---

### Task 1: AeroSpace Config Parser & macOS Global Shortcuts Provider

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_parsers.swift`

**Interfaces:**
- Produces: `AeroSpaceConfigParser.parse(atPath:) -> [ShortcutGroup]`
- Produces: `MacOSGlobalShortcuts.getGroups() -> [ShortcutGroup]`

- [ ] **Step 1: Write test script `/tmp/test_parsers.swift`**
Test `AeroSpaceConfigParser` against `/Users/ablack/.config/aerospace/aerospace.toml` and verify that categories ("Window Focus & Navigation", "Workspaces", "Window Movement & Layout") and key chords (`alt-h` -> `⌥H`, `alt-shift-h` -> `⌥⇧H`) are produced accurately.

- [ ] **Step 2: Run test script to verify failure / initial state**
Run: `swift /tmp/test_parsers.swift`
Expected: Fails because parser is not yet defined.

- [ ] **Step 3: Implement `AeroSpaceConfigParser` and `MacOSGlobalShortcuts` in `KeyHUD.swift`**
Add parser that reads TOML key-bindings, maps modifiers (`alt` -> `⌥`, `cmd` -> `⌘`, `ctrl` -> `⌃`, `shift` -> `⇧`), and groups them into logical categories. Add `MacOSGlobalShortcuts` with standard macOS categories.

- [ ] **Step 4: Run test script to verify passing output**
Run: `swift /tmp/test_parsers.swift`
Expected: Outputs parsed ShortcutGroups for AeroSpace and macOS.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add AeroSpace config parser and macOS global shortcuts provider"
```

---

### Task 2: Scope Data Model & Scope Dropdown in HUD Header

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Consumes: `AeroSpaceConfigParser`, `MacOSGlobalShortcuts`
- Produces: `enum HUDScope: Hashable, Identifiable`, `HUDView.currentScope`

- [ ] **Step 1: Define `HUDScope` and scope-switching state in `KeyHUD.swift`**
Create `HUDScope` enum: `.activeApp(name: String, bundleID: String, icon: NSImage?)`, `.aerospace`, `.macos`, and optional custom globals.
In `HUDView`, track `@State private var selectedScope: HUDScope = .activeApp(...)`.

- [ ] **Step 2: Update Header in `HUDView` to replace static app title with interactive Menu**
Render the app icon or scope icon (Apple logo for macOS, grid icon for AeroSpace) alongside a Menu button showing the current scope name with a `chevron.down`.
The menu displays:
  - Active App (with app icon)
  - AeroSpace Tiling (`square.grid.2x2` / `macwindow.on.rectangle`)
  - macOS System (`apple.logo`)
When clicked, changes `selectedScope`.

- [ ] **Step 3: Dynamically compute `displayedGroups` based on `selectedScope`**
When `selectedScope == .activeApp`, show the active app's `groups`.
When `selectedScope == .aerospace`, show AeroSpace parsed groups.
When `selectedScope == .macos`, show macOS global groups.
Reset search query and selection indices on scope change.

- [ ] **Step 4: Build and test compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`
Expected: Success.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add HUD header scope switcher dropdown with AeroSpace and macOS scopes"
```

---

### Task 3: Execution Handling for AeroSpace & Global Shortcuts & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Consumes: `ActionExecutor.execute`
- Produces: Global shortcut keystroke synthesis / AeroSpace command dispatch

- [ ] **Step 1: Enhance `ActionExecutor` to support AeroSpace commands and global keystrokes**
When executing a shortcut from AeroSpace, if it has a command or keystroke, synthesize the keystroke to the system (or run `aerospace <command>` if applicable). For macOS global shortcuts, synthesize the keystroke with CGEvent.

- [ ] **Step 2: Update `TODO.md` to reflect completed Global Shortcuts & Scope Switcher**
Check off the items under `Global Shortcuts Section (System-wide, similar to KeyClu)`.

- [ ] **Step 3: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```
Verify the app runs cleanly and opens with the new Scope Switcher dropdown in the header.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md
git commit -m "feat: complete global shortcuts and scope switcher dropdown implementation"
```
