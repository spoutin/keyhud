# Design Specification: Conflict Summary Banner in Keybinding Editor

## 1. Intent & Purpose
When configuring shortcuts, users need an immediate, high-visibility summary of all detected collisions without having to hunt through categories.
A dedicated **Conflict Summary Banner** at the top of the Keybinding Editor provides:
1. **At-a-Glance Count & Breakdown**: Shows total conflicts (e.g. `2 App Conflicts`, `1 Global Collision`).
2. **Interactive Expandable List**: Clicking "View Details" reveals a list of all collisions in one compact box:
   - Showing the shortcut combination (e.g. `⌘P`)
   - The colliding commands (e.g. *"Print"* vs *"Quick Open"*, or *"Focus Left"* vs *AeroSpace*)
   - Quick jump link / filter to instantly jump to or filter those items.
3. **Quick Resolve / Filter Action**: A prominent button (`Filter Conflicts`) to isolate and resolve them immediately.

---

## 2. Technical Architecture & UI Model

### 2.1 Conflict Summary Extraction
Add a helper in `EditorState`:
```swift
struct ConflictSummaryItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let keys: String
    let conflicts: [ConflictSeverity]
}

func allConflictSummaries() -> [ConflictSummaryItem]
```
This iterates over the active app's categories, finds all items where `conflicts.count > 0`, and aggregates them.

### 2.2 Visual Layout in `KeybindingEditorView`
Placed right below the top navigation toolbar (above the categories list):
```
┌────────────────────────────────────────────────────────────────────────┐
│ ⚠️ 3 Hotkey Conflicts Detected                                         │
│ 2 internal duplicates within Ghostty, 1 collision with AeroSpace.      │
│ [Show Details ▾]                      [Filter Conflicting Rows]        │
│                                                                        │
│ ▼ Details (when expanded):                                             │
│   • ⌘P   "Print" (File) collides with "Quick Open" (Tools)             │
│   • ⌥H   "Move Left" (Navigation) collides with AeroSpace "Focus Left"  │
└────────────────────────────────────────────────────────────────────────┘
```
- Orange/yellow gradient container with subtle border.
- Disappears automatically when 0 conflicts exist.

---

## 3. Goals & Non-Goals
- **Goals**:
  - High visibility: impossible to miss when editing keybindings.
  - Interactive: can expand to see the full list of collisions in one place.
  - Automatically updates in real time as keys are modified.
- **Non-Goals**:
  - Forcing the user to resolve them before saving (still advisory).
