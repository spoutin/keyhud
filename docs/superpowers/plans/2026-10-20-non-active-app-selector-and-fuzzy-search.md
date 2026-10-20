# Non-Active App Selector with Fuzzy Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow selecting non-active running apps from the HUD dropdown with clear section dividers, add fuzzy searching to the app picker, and upgrade the shortcut search bar to support universal fuzzy matching.

**Architecture:** Create `FuzzyMatcher` utility. Upgrade `HUDView.filteredGroups` to fuzzy-match shortcut titles and keys. Extend `HUDScope` to support any selected running application (`.runningApp(app: NSRunningApplication)`). Organize the Scope dropdown menu with distinct sections (Active App & Tools, Globals, Other Running Apps) and an optional inline search filter.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-non-active-app-selector-and-fuzzy-search-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No third-party dependencies.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. Fuzzy matching accurately handles typos and abbreviated chords (e.g. "pds" -> Pods, "cmt" -> Commit, "spl" -> Split).
2. Selecting a non-active app loads its scanned menu bar and custom shortcuts without crashing or stealing window focus.
3. Section dividers clearly delineate Active App, Globals, and Other Apps.
4. Clicking to execute a shortcut from a non-active app correctly activates that app before dispatching.

---

### Task 1: Fuzzy Search Algorithm (`FuzzyMatcher`) & Shortcut Search Upgrade

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_fuzzy_matcher.swift`

**Interfaces:**
- Produces: `FuzzyMatcher.matches(pattern:target:) -> Bool`
- Produces: `FuzzyMatcher.score(pattern:target:) -> Int?`

- [ ] **Step 1: Write test script `/tmp/test_fuzzy_matcher.swift`**
Validate fuzzy matching for abbreviations (e.g. "gcm" matches "Google Chrome", "spl" matches "Split Horizontal", "pds" matches "Pods View").

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_fuzzy_matcher.swift`

- [ ] **Step 3: Implement `FuzzyMatcher` in `KeyHUD.swift` and upgrade `HUDView.filteredGroups`**
Replace `.contains(q)` with `FuzzyMatcher.matches(pattern: q, target: title) || FuzzyMatcher.matches(pattern: q, target: keys)`. Sort results by match score for highest relevance.

- [ ] **Step 4: Build and test compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add FuzzyMatcher and upgrade shortcut search to fuzzy matching"
```

---

### Task 2: Non-Active Running Apps in Scope Dropdown with Section Dividers

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Produces: `HUDScope.runningApp(app: NSRunningApplication)`
- Produces: Structured scope dropdown with Active App, Globals, and Other Running Apps sections

- [ ] **Step 1: Extend `HUDScope` to support inspecting any running app**
Add `.runningApp(app: NSRunningApplication)` case. Compute groups dynamically by scanning the target app or loading its custom shortcuts.

- [ ] **Step 2: Reorganize Scope Menu with clean dividers and other running apps**
In `HUDView`:
  - **ACTIVE APPLICATION**: Active app + Ghostty sub-profiles if applicable.
  - **Divider**: `--- GLOBAL SHORTCUTS ---`
  - AeroSpace Tiling & macOS System.
  - **Divider**: `--- OTHER RUNNING APPS ---`
  - Query `NSWorkspace.shared.runningApplications` for regular apps, excluding the active app, showing each app's icon and localized name.
  - Selecting any running app switches the HUD view to display its shortcuts immediately.

- [ ] **Step 3: Update `TODO.md`**
Record the new feature in `TODO.md`.

- [ ] **Step 4: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: add non-active running apps selector to scope dropdown with section dividers"
```
