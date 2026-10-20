# Design Specification: Non-Active App Selector with Fuzzy Search & Universal Fuzzy Matcher

## 1. Intent & Purpose

Users need to view shortcuts for other running Mac applications from the HUD even when that app is not the currently active window. Furthermore, users need a fast, forgiving search experience:
1. **Fuzzy Scope/App Search**: Rapidly find and switch to any running application or global tools from the header dropdown without wading through long lists.
2. **Visual Separation**: Clearly distinguish between the **Active Application**, **Global Toolsets** (AeroSpace, macOS System, Terminal Tools), and **Other Running Applications** with clean divider lines and section headers.
3. **Universal Fuzzy Shortcut Matching**: Both the app selector and the shortcut search bar should use fuzzy matching (matching non-consecutive letters in sequence, e.g., "gcm" matches "Google Chrome" or "git commit", "cm" matches "Commit", "spl" matches "Split") rather than rigid substring matching.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Fuzzy Search Algorithm (`FuzzyMatcher`)**:
  - Implements character subsequence matching with smart scoring:
    - Matches characters in order with case-insensitivity.
    - Higher score for prefix matches, word boundary matches (after spaces, capitals, colons, or slashes), and consecutive matching characters.
    - Replaces rigid `.contains()` checks in shortcut search and app selection.
- **Top-Left Scope Dropdown Structure**:
  - Clicking the pill opens a menu / searchable popover view:
    - **ACTIVE CONTEXT**:
      - `[App Icon] (Active App Name)` (marked as active)
      - If Ghostty: nested/grouped `Terminal Tools`
    - **GLOBAL TOOLS** (separated by clear divider):
      - `[macwindow.on.rectangle] AeroSpace Tiling`
      - `[apple.logo] macOS System`
    - **RUNNING APPLICATIONS** (separated by clear divider):
      - Lists all running regular applications (e.g. Google Chrome, Slack, Obsidian, Finder, Teams, etc.) with their real icons.
      - Selecting an inactive app immediately scans/loads its shortcuts and updates the HUD without needing to switch active applications.
  - Quick fuzzy search filter in the dropdown when there are many running apps.
- **HUD Fuzzy Shortcut Search**:
  - Upgrade `HUDView.filteredGroups` to use `FuzzyMatcher` so searching "dpl" matches "Deployments View", "pds" matches "Pods View", "spl" matches "Split Horizontal", etc.

### Non-Goals
- Launching unopened applications from the menu (focuses on currently running apps + configured custom profiles).

---

## 3. Architecture & Data Model

### Fuzzy Matcher
```swift
struct FuzzyMatcher {
    static func score(pattern: String, target: String) -> Int?
    static func matches(pattern: String, target: String) -> Bool
}
```

### Running App Model
```swift
struct RunningAppItem: Identifiable, Hashable {
    let id: String // bundleID
    let name: String
    let icon: NSImage
    let app: NSRunningApplication
}
```
