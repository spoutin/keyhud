# Design Specification: Bookmarks & Favorites (Starring & Pinned Favorites Group)

## 1. Intent & Purpose
In any application cheatsheet (native app or terminal tool), users frequently find themselves looking for a small subset of essential shortcuts over and over again. Bookmarks & Favorites allows users to star their favorite shortcuts:
- Starred shortcuts appear in a dedicated, pinned **⭐ Favorites** column at the top-left of the cheatsheet.
- In their original sections, starred shortcuts display a gold star icon (`star.fill`) and a subtle accent tint so they are instantly recognizable.
- Clicking the star icon on hover toggles favorite status on/off with persistent storage in `UserDefaults` per bundle ID / scope.

---

## 2. Requirements & Data Model

### 2.1 Persistence
Favorites are stored as a map of `[String: [String]]` (bundleID / tool scope key -> list of shortcut titles or identifiers):
- Key in `UserDefaults`: `"bookmarkedShortcuts"`
- Stored as `[String: [String]]` (e.g. `["com.mitchellh.ghostty": ["Split Horizontal", "Close Tab"]]`)
- Helper manager: `FavoritesManager.shared`:
  - `isBookmarked(bundleID: String, title: String) -> Bool`
  - `toggleBookmark(bundleID: String, title: String)`
  - `allBookmarks(for bundleID: String) -> Set<String>`

### 2.2 Visual Presentation & Layout
1. **Interactive Star Toggle**:
   - On each shortcut row (`ShortcutRowView`), a star icon appears:
     - Filled gold star (`star.fill`, `.yellow`) if bookmarked.
     - Unfilled subtle star (`star`, `Color.white.opacity(0.3)`) when hovered if not bookmarked.
   - Clicking the star toggles the bookmark without executing the shortcut.
2. **Pinned "⭐ Favorites" Column**:
   - When one or more items in the current scope are bookmarked, a new group `ShortcutGroup(title: "⭐ Favorites", items: [...])` is prepended to `currentScopeGroups` at index 0.
   - The items in this group preserve their original keys, execution callbacks, and clickability.
   - If no items are bookmarked for that scope, no favorites column is displayed.
3. **Keyboard Navigation & Search**:
   - Works seamlessly with existing 2D arrow navigation and fuzzy search.
   - Searching also matches items inside the ⭐ Favorites column.

---

## 3. Goals, Non-Goals & Anti-Goals
- **Goals**: Quick 1-click starring, instant visual recall via top-left pinned column, zero lag, persistent across app restarts.
- **Non-Goals**: Syncing bookmarks to cloud (local `UserDefaults` is sufficient).
