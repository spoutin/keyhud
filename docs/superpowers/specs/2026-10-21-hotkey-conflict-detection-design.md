# Design Specification: Conflict Detection for Hotkeys (Internal & Global)

## 1. Intent & Purpose
When assigning or using shortcuts, keybinding collisions happen frequently:
1. **App-Internal Conflicts**: Two commands in the same application share the same hotkey (e.g. `⌘P` assigned to *"Print"* and *"Quick Open"*, or `sgh` assigned to two actions). One command will silently shadow or break the other.
2. **Global System & AeroSpace Collisions**: An application shortcut collides with an active system-wide hotkey:
   - AeroSpace window management bindings (`⌥H`, `⌥J`, `⌥K`, `⌥L`, `⌥F`, etc.)
   - macOS System shortcuts (`⌘Space`, `⌘⇧4`, `⌘⇥`, `⌘⌥Esc`, etc.)
   - KeyHUD's own hotkey (`⌘⇧/`)

Users need proactive detection, real-time warning feedback while recording, visual conflict badges in the Keybinding Editor and HUD, and a quick one-click filter to audit all conflicts.

---

## 2. Technical Architecture & Data Model

### 2.1 Conflict Classification
```swift
enum ConflictType: Equatable {
    case internalApp(otherTitle: String, category: String)
    case aeroSpace(action: String)
    case macosSystem(action: String)
    case keyhudGlobal
}
```

### 2.2 Shortcut Normalization & Canonical Matching
Shortcuts can be formatted with varying modifier orders or whitespace (e.g. `⌘⇧P` vs `⇧⌘P`, `alt+h` vs `⌥H`, `cmd+shift+/` vs `⌘⇧/`).
`ShortcutNormalizer.canonical(keys:) -> String`:
- Sorts modifiers canonically (`⌃`, `⌥`, `⇧`, `⌘`).
- Standardizes key tokens and lowercases letters.
- Splits alternate variants (`/`) so each variant is checked independently against other variants.

### 2.3 Conflict Detector Engine (`ShortcutConflictDetector`)
- **`findConflicts(inApp: bundleID, config: [String: [String: [[String: String]]]]) -> [String: [ConflictType]]`**
  - Maps canonical key -> list of `(bundleID, category, title)`.
  - Maps each shortcut item in the app to any internal conflicts.
- **`checkGlobalConflict(keys: String) -> ConflictType?`**
  - Compares canonical key against:
    - Active AeroSpace bindings parsed via `AeroSpaceConfigParser.parse()`
    - Built-in macOS System bindings from `MacOSGlobalShortcuts.getGroups()`
    - KeyHUD activation hotkey (`⌘⇧/`)

### 2.4 User Interface Integration

1. **In Keybinding Editor Rows**:
   - If an item has conflicts, display an orange/red badge next to the title or keys:
     - ⚠️ `[Conflict: "Other Title"]`
     - ⚡ `[Global: AeroSpace "Focus Left"]`
   - Tooltip details explain the conflict and which shortcut is shadowed.

2. **In Interactive Recorder (`RecordingBadgeView`)**:
   - While recording a key sequence/chord:
     - If the currently typed combo matches an existing binding in the app or system, display a live warning banner inside the recording pill:
       `⚠️ Collides with: "Print"`
     - Non-blocking: users can still click **Done** if they intentionally want the duplicate, but they are fully aware of it.

3. **In Keybinding Editor Toolbar ("Audit Conflicts")**:
   - Add a filter button: `Filter Conflicts (N)`
   - When active, filters the editor list to only categories and shortcuts that have conflicts.

4. **In HUD Cheatsheet View**:
   - In `ShortcutRow`, display a subtle warning icon `[!]` on conflicting rows with a hover tooltip explaining the collision.

---

## 3. Goals & Non-Goals
- **Goals**:
  - Zero false-positives by canonicalizing modifier ordering.
  - Non-blocking warnings: informs the user without disabling their controls.
  - Instant live feedback while recording.
  - 100% testable with automated unit tests.
- **Non-Goals**:
  - Overwriting other apps' system files automatically.
