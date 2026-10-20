# Design Specification: Adjustable Search Scope (Current, Current + Sub-apps, Global)

## 1. Intent & Purpose

When searching for shortcuts in KeyHUD, users currently search only what is displayed in the active view. If a user is on Ghostty's main view or Chrome, but wants to quickly find a Neovim binding, an AeroSpace binding, or a macOS shortcut, they currently have to manually change the view scope first.

This feature introduces an **Adjustable Search Scope**:
1. **Search Scope Modes**:
   - `Current View`: searches only the columns currently displayed on screen.
   - `Current + Sub-tools`: searches the active app plus all its sub-profiles/tools (e.g. for Ghostty, searches Ghostty, Neovim, Zsh, K9s, Lazygit, Atuin, VisiData).
   - `All / Global`: searches across all apps and tools, including AeroSpace and macOS System shortcuts.
2. **Interactive Toggle in the HUD View**: A compact pill / menu button located right next to the search bar allowing the user to toggle or select the active search scope on the fly.
3. **Configurable Default in Settings**: A setting in Settings (under **General** or **Shortcuts**) to choose the default search scope whenever KeyHUD opens.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **SearchScope Enum**:
  - `current`: "Current View" (`macwindow`)
  - `currentAndSubApps`: "Current + Sub-tools" (`square.stack.3d.up`)
  - `global`: "All / Global" (`globe`)
- **HUD View Search Bar Toggle**:
  - A compact icon/pill button integrated into or beside the search field that displays the current search scope icon and opens a menu to toggle modes.
- **Search Resolution Engine**:
  - When query is active, resolve the candidate pool of `ShortcutGroup`s based on `SearchScope`:
    - `current`: filters `currentScopeGroups`.
    - `currentAndSubApps`: if Ghostty, includes all Ghostty categories (main + all sub-tools).
    - `global`: combines current app groups, all Ghostty tools, AeroSpace parsed groups, and macOS system shortcuts.
- **Settings Configuration**:
  - Add `defaultSearchScope` to `AppSettings` and render a picker in Settings under the **General** tab.

### Non-Goals
- Full-text web search (search remains local to configured and scanned shortcuts).

---

## 3. Architecture & Data Model

### SearchScope Enum
```swift
enum SearchScope: String, CaseIterable, Identifiable {
    case current = "Current View"
    case currentAndSubApps = "Current + Sub-tools"
    case global = "All / Global"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .current: return "macwindow"
        case .currentAndSubApps: return "square.stack.3d.up"
        case .global: return "globe"
        }
    }
}
```

### AppSettings Addition
```swift
@Published var defaultSearchScope: String
```

### SearchState Addition
```swift
@Published var activeSearchScope: SearchScope
```
