# Bookmarks & Favorites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement interactive shortcut bookmarking (starring), persistent storage per app, in-place gold star badges, and an automatically prepended "⭐ Favorites" column.

**Architecture:** Create `FavoritesManager: ObservableObject` managing `bookmarks: [String: Set<String>]` with `UserDefaults` serialization. Update `ShortcutRowView` to display interactive star button on hover/bookmarked. Inject a synthetic `ShortcutGroup(title: "⭐ Favorites", items: ...)` at column 0 in `HUDView.currentScopeGroups` whenever bookmarks exist.

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-bookmarks-and-favorites-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Clicking the star button toggles favorite status without triggering the shortcut's action.
2. Starred items appear in the first column under "⭐ Favorites" and display a gold star in both columns.
3. Unstarring an item immediately updates the UI and removes it from the "⭐ Favorites" column.
4. If all items in a scope are unstarred, the "⭐ Favorites" column disappears cleanly and the window shrink-to-fit smoothly updates.
5. All bookmarks persist across restarts.

---

### Task 1: FavoritesManager & Storage Engine

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_favorites_manager.swift`

**Interfaces:**
- Produces: `FavoritesManager.shared.isBookmarked(scopeKey:title:) -> Bool`
- Produces: `FavoritesManager.shared.toggleBookmark(scopeKey:title:)`
- Produces: `FavoritesManager.shared.bookmarks(for scopeKey: String) -> Set<String>`

- [ ] **Step 1: Write unit test `/tmp/test_favorites_manager.swift`**
Validate adding, checking, toggling, and persistence serialization of bookmarks.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_favorites_manager.swift`

- [ ] **Step 3: Implement `FavoritesManager` in `KeyHUD.swift`**
Add `class FavoritesManager: ObservableObject` with `@Published var bookmarksMap: [String: [String]]`.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: implement FavoritesManager with persistent storage"
```

---

### Task 2: Interactive Star Button in ShortcutRowView & Prepended Favorites Column

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

**Interfaces:**
- Produces: Star toggle in `ShortcutRowView`
- Produces: "⭐ Favorites" group in `currentScopeGroups`

- [ ] **Step 1: Update `ShortcutRowView` with Star Button**
Add interactive star toggle (`star.fill` yellow when bookmarked, subtle `star` on hover). Clicking star invokes `FavoritesManager.shared.toggleBookmark(...)` without firing `onExecute`.

- [ ] **Step 2: Prepend "⭐ Favorites" group in `HUDView.currentScopeGroups`**
For the active scope, gather all items whose title is bookmarked. If non-empty, insert `ShortcutGroup(title: "⭐ Favorites", items: favItems)` at index 0.

- [ ] **Step 3: Update `TODO.md`**
Mark "Bookmarks & Favorites" as completed in `TODO.md`.

- [ ] **Step 4: Build, sign, and install `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: complete interactive shortcut starring and pinned favorites group"
```
