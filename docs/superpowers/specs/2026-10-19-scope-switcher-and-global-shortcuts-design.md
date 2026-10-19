# Design Specification: Scope Switcher & Global Shortcuts (AeroSpace, macOS System, Custom Globals)

## 1. Intent & Purpose

Users often want to inspect system-wide and window manager shortcuts (such as AeroSpace tiling window manager and macOS global shortcuts) in addition to active application keybindings. Currently, KeyHUD only shows the frontmost application. 

This feature adds a **Scope Switcher Dropdown** in the HUD header where the current app name and icon sit. Users can instantly switch between the **Active Application**, **AeroSpace Tiling**, **macOS System Globals**, or other configured global apps, with dedicated icons for each.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Header Scope Dropdown**:
  - Located in the top-left of the HUD header in place of the static App Icon & Name.
  - Interactive dropdown showing the current scope with a clean dropdown chevron (`chevron.down`).
  - Dropdown options:
    1. **Active Application** (default): dynamically follows the focused app with its native app icon.
    2. **AeroSpace Tiling**: custom grid icon (`macwindow.on.rectangle` / `square.grid.2x2`), showing AeroSpace bindings parsed from `~/.config/aerospace/aerospace.toml`.
    3. **macOS System Globals**: Apple icon (`apple.logo`), showing universal Mac shortcuts (App Switching, Screenshots, Window Management, Mission Control).
    4. Any additional global scopes defined in `custom_shortcuts.json` (under `"global"` or custom bundle IDs).
- **AeroSpace Parser**:
  - Dynamically reads `~/.config/aerospace/aerospace.toml` on demand.
  - Groups bindings cleanly into categories:
    - *Window Focus & Navigation* (`alt-h`, `alt-j`, `alt-k`, `alt-l`, `focus-monitor`, etc.)
    - *Window Movement & Layout* (`alt-shift-h`, `alt-slash` tiles, `alt-comma` accordion, etc.)
    - *Workspaces* (`alt-1`, `alt-2`, `alt-a` through `alt-z`, `workspace-back-and-forth`)
    - *Move Node to Workspace* (`alt-shift-1`, `alt-shift-2`, etc.)
    - *Service Mode & Reload* (`alt-shift-;`, reload, etc.)
  - Translates AeroSpace key format (e.g. `alt-shift-h` -> `⌥⇧H`, `ctrl-shift-1` -> `⌃⇧1`) to match KeyHUD's tokenized visual badge format.
- **macOS System Shortcuts**:
  - Comprehensive, built-in system cheat sheet:
    - *Window & App Management* (`⌘Tab`, `⌘~`, `⌘H`, `⌘M`, `⌘W`, `⌘Q`)
    - *Screen Capture* (`⌘⇧3` Full Screen, `⌘⇧4` Area/Window, `⌘⇧5` Options/Record, `⌘⌃⇧4` Clipboard)
    - *Mission Control & Spaces* (`⌃↑` Mission Control, `⌃↓` App Expose, `⌃←` / `⌃→` Switch Space, `⌘Space` Spotlight)
    - *System & Accessibility* (`⌘⌥Esc` Force Quit, `⌃⌘Q` Lock Screen, `⌘⌥D` Toggle Dock)
- **Seamless Filtering & Search**:
  - Switching scopes immediately repopulates the column grid and resets search selection without dismissing the HUD.
  - Full 2D keyboard navigation (`Up`/`Down`/`Left`/`Right`/`Enter`) and search work identically across all scopes.

### Non-Goals
- Modifying AeroSpace's `aerospace.toml` from KeyHUD (KeyHUD reads and presents the shortcuts; users edit their config directly or via local editor).
- Intercepting and overriding macOS default global hotkeys.

### Anti-Goals
- Cluttering the main app view with multiple simultaneous global columns by default; using an explicit Scope Dropdown keeps the screen uncluttered and focused.

---

## 3. Architecture & Data Model

### Scope Model
```swift
enum HUDScope: Hashable, Identifiable {
    case activeApp(name: String, bundleID: String, icon: NSImage?)
    case aerospace
    case macos
    case custom(id: String, name: String, iconName: String)

    var id: String {
        switch self {
        case .activeApp(_, let bundleID, _): return "app:\(bundleID)"
        case .aerospace: return "aerospace"
        case .macos: return "macos"
        case .custom(let id, _, _): return "custom:\(id)"
        }
    }

    var displayName: String {
        switch self {
        case .activeApp(let name, _, _): return name
        case .aerospace: return "AeroSpace Tiling"
        case .macos: return "macOS System"
        case .custom(_, let name, _): return name
        }
    }
}
```

### AeroSpace Config Parser (`AeroSpaceParser`)
- Checks if `~/.config/aerospace/aerospace.toml` exists.
- Extracts `[mode.main.binding]` and `[mode.service.binding]` sections.
- Converts `alt-` to `⌥`, `cmd-` to `⌘`, `ctrl-` to `⌃`, `shift-` to `⇧`.
- Produces `[ShortcutGroup]` organized by functional categories.

---

## 4. User Experience & Interactions

1. **Opening the HUD**: Opens to `.activeApp` by default.
2. **Selecting a Scope**: Clicking the header title/icon opens an `NSMenu` or SwiftUI `Menu` listing:
   - `[App Icon] (App Name)` (e.g. Google Chrome, Ghostty)
   - `[Window Grid Icon] AeroSpace Tiling`
   - `[Apple Icon] macOS System`
3. **Execution**:
   - Selecting a shortcut in `.activeApp` performs the action on that target app.
   - Selecting an AeroSpace shortcut can synthesize the keystroke or execute `aerospace <command>` via CLI.
