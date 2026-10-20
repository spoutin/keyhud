# Universal Command Palette Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn KeyHUD into a universal macOS Command Palette (Paletro-style) by indexing and executing all menu actions with or without shortcuts, configurable in Settings and togglable in the HUD.

**Architecture:**
- Update `MenuScanner` to index all executable menu items (items without keybindings store `keys: ""`).
- Add `commandPaletteMode` to `AppSettings` (`"searchOnly"`, `"always"`, `"off"`).
- Add `isCommandPaletteActive` in `SearchState` and a Command Palette toggle button (`command.circle`) in the HUD header.
- Filter or include actions based on active setting and search query state.
- Render `ShortcutRow` with a subtle `[ Action ]` pill for items without shortcut keys.

**Tech Stack:** Swift, SwiftUI, AppKit, Accessibility API.

**Spec:** `docs/superpowers/specs/2026-10-20-universal-command-palette-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros in `KeyHUD.swift`.

## Review Focus
1. When searching in Command Palette mode, menu items without shortcuts (e.g. "Export As...") appear in search results.
2. Clicking or pressing `Enter` on an action item triggers `AXUIElementPerformAction(kAXPressAction)`.
3. Action items render cleanly in `ShortcutRow` with an `Action` badge.
4. Settings in **General** tab allows choosing between `During Search Only` (default), `Always`, and `Off`.
5. HUD toolbar button toggles Command Palette mode on/off reactively.

---

### Task 1: MenuScanner Indexing & ActionExecutor Execution

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_menu_scanner.swift`

**Interfaces:**
- Produces: `MenuScanner.scan(app:includeAllActions:) -> [ShortcutGroup]`
- Produces: `ActionExecutor.shared.execute(item:targetApp:)`

- [ ] **Step 1: Write standalone test script `/tmp/test_menu_scanner.swift`**
Verify structure of menu items with `keys: ""` and execution caching.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_menu_scanner.swift`

- [ ] **Step 3: Update `MenuScanner` in `KeyHUD.swift`**
Update `MenuScanner` to support `includeAllActions: Bool` and retain hierarchical path for items without shortcuts.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Command Palette Settings & HUD Quick Toggle

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Add `commandPaletteMode` to `AppSettings`**
Values: `"searchOnly"` (default), `"always"`, `"off"`.
Add UI controls in `SettingsView` General tab under a new "COMMAND PALETTE MODE" card.

- [ ] **Step 2: Add `isCommandPaletteActive` to `SearchState`**
Allows toggling Command Palette mode in the HUD view.

- [ ] **Step 3: Add Command Palette Button in HUD Header**
Beside the Eye button:
`Button(action: { searchState.isCommandPaletteActive.toggle() })`
Icon: `Image(systemName: searchState.isCommandPaletteActive ? "command.circle.fill" : "command.circle")`

- [ ] **Step 4: Update `ShortcutRow` for Items Without Shortcuts**
Render `[ Action ]` or `[ ⏎ Run ]` pill badge when `item.keys.isEmpty`.

- [ ] **Step 5: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 3: Group Filtering & Execution Verification

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Wire `currentScopeGroups` and `searchableGroups`**
Include action items when:
- `searchState.isCommandPaletteActive` is `true`, OR
- `settings.commandPaletteMode == "always"`, OR
- `settings.commandPaletteMode == "searchOnly"` and `!searchState.query.isEmpty`.

- [ ] **Step 2: Update `TODO.md`**
Mark Universal Command Palette Mode as completed.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: universal command palette mode for all menu actions"
```
