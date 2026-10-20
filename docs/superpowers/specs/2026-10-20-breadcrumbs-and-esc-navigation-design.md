# Design Specification: Header Breadcrumbs & Esc-to-Go-Back Navigation Stack

## 1. Intent & Purpose

As users navigate through the HUD—from an application into a sub-tool (e.g. `Ghostty ➔ Terminal Tools ➔ Neovim` or `Ghostty ➔ K9s`) or between different applications and global scopes—they need visual context of where they are in the hierarchy and a natural way to navigate backwards.

This feature adds:
1. **Interactive Header Breadcrumb Trail**: Showing the trail of navigation segments (e.g., `Ghostty` › `Terminal Tools` › `Neovim`) with direct clickability to return to any prior level.
2. **Hierarchical Esc-to-Go-Back Stack**: Pressing `Esc` systematically unwinds state:
   - First `Esc` clears active search text (if any).
   - Subsequent `Esc` pops the navigation stack back to the previous breadcrumb level.
   - When reaching the root level (no more history), `Esc` closes the HUD.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Navigation Stack (`SearchState.navigationStack`)**:
  - Pushes the previous `HUDScope` when navigating into a new scope.
  - Exposes `canGoBack: Bool` and `popScope() -> Bool`.
- **Breadcrumbs UI in Header**:
  - If at root: shows the single scope dropdown pill.
  - If in a sub-tool or navigated scope: shows the interactive breadcrumb trail:
    - `[Root Scope Name]` › `[Current Scope Name]`
    - Each previous crumb is clickable to quickly jump back.
- **Esc Key Unwind Flow**:
  1. If `searchState.query` is not empty ➔ clear `query`.
  2. Else if `searchState.canGoBack` ➔ `searchState.popScope()`.
  3. Else if `AppSettings.shared.isPinned` ➔ unpin.
  4. Else ➔ `HUDWindowController.shared.hide()`.
- **Keyboard & Search Reset**:
  - Going back automatically resets column and item selection indices so the user lands on the first item of the parent view.

### Non-Goals
- Browser-style forward button (only backward history stack is needed).

---

## 3. Architecture & Data Model

### Navigation Entry
```swift
struct BreadcrumbItem: Identifiable, Equatable {
    let id = UUID()
    let scope: HUDScope
    let title: String
    let iconName: String?
}
```

### SearchState Extensions
```swift
class SearchState: ObservableObject {
    @Published var scopeHistory: [HUDScope] = []

    var canGoBack: Bool { !scopeHistory.isEmpty }

    func pushScope(_ newScope: HUDScope) {
        if selectedScope != newScope {
            scopeHistory.append(selectedScope)
            selectedScope = newScope
        }
    }

    func popScope() -> Bool {
        guard let prev = scopeHistory.popLast() else { return false }
        selectedScope = prev
        return true
    }

    func clearHistory() {
        scopeHistory.removeAll()
    }
}
```
