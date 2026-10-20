# Adjustable Search Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement adjustable search scope modes (Current, Current + Sub-tools, Global) with an interactive toggle in the HUD search bar and configurable default in Settings.

**Architecture:** Create `SearchScope` enum, add `defaultSearchScope` to `AppSettings`, track `activeSearchScope` in `SearchState`. Update `HUDView.filteredGroups` to aggregate candidates across the selected search scope when a query is typed. Add a search scope menu toggle beside the search textfield.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-adjustable-search-scope-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No third-party package dependencies.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. When query is empty, the HUD shows standard columns for the active view without dumping all global shortcuts.
2. When query is typed with "Global" selected, results from other scopes (e.g. AeroSpace or Neovim) appear seamlessly.
3. Clicking or pressing Enter on an item from a different scope executes properly.
4. Changing the default in Settings persists across app relaunches.

---

### Task 1: Search Scope Data Model & Search Aggregation Engine

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_search_scope.swift`

**Interfaces:**
- Produces: `enum SearchScope: String, CaseIterable, Identifiable`
- Produces: `AppSettings.defaultSearchScope: String`
- Produces: `SearchState.activeSearchScope: SearchScope`

- [ ] **Step 1: Write test script `/tmp/test_search_scope.swift`**
Validate `SearchScope` enum parsing and filtering behavior.

- [ ] **Step 2: Run test script to verify**
Run: `swift /tmp/test_search_scope.swift`

- [ ] **Step 3: Implement `SearchScope`, `AppSettings.defaultSearchScope`, and multi-scope aggregation in `KeyHUD.swift`**
Update `HUDView.filteredGroups`:
  - If query is empty: returns `currentScopeGroups`.
  - If query is non-empty: resolves candidates according to `searchState.activeSearchScope`:
    - `.current`: filters `currentScopeGroups`.
    - `.currentAndSubApps`: filters all `groups` for current app (including all sub-profiles).
    - `.global`: filters `groups` + `AeroSpaceConfigParser.parse()` + `MacOSGlobalShortcuts.getGroups()`.

- [ ] **Step 4: Build with `build.sh` to verify compilation**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: implement SearchScope and multi-scope search aggregation"
```

---

### Task 2: HUD Search Scope Toggle & Settings Configuration & TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Produces: Search scope toggle button beside search bar in `HUDView`
- Produces: Default search scope picker in `SettingsView` (General tab)

- [ ] **Step 1: Add Search Scope Menu Button beside Search Bar in `HUDView`**
Add a pill button inside/beside the search container showing `searchState.activeSearchScope.icon` with a Menu to switch between `Current View`, `Current + Sub-tools`, and `All / Global`.

- [ ] **Step 2: Add Default Search Scope Setting in `SettingsView`**
In the General tab under Settings, add a "DEFAULT SEARCH SCOPE" picker so users can configure what scope new HUD sessions start with.

- [ ] **Step 3: Update `TODO.md`**
Add and check off the Adjustable Search Scope task in `TODO.md`.

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
git commit -m "feat: add HUD search scope toggle and configurable settings default"
```
