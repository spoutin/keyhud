# Design Specification: Settings Tabs, Appearance Modes, and High-Contrast Dropdown

## 1. Intent & Purpose

Users need a consistent and polished visual experience between the main HUD and Settings, with support for Dark, Light, and Automatic system appearances. Furthermore, as Settings options have grown, organizing Settings into clear top navigation tabs (General, Appearance, Shortcuts) prevents endless scrolling and makes window sizing and visual customizations intuitive to find. Lastly, the HUD Scope Dropdown button needs a crisp, native-standard design pattern so that the dropdown chevron is distinct and readable in both dark and light modes.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **High-Contrast Standard Dropdown Button**:
  - Replace low-contrast header text button with a standard macOS pill button:
    - Subtle translucent background with a crisp border stroke.
    - High-contrast chevron (`chevron.up.chevron.down` or bold `chevron.down`).
    - Works cleanly in both light and dark themes.
- **Top Tabs in Settings**:
  - Segmented tab bar at the top of Settings:
    1. **General** (Activation triggers, Command hold duration slider, System Accessibility permission card).
    2. **Appearance** (Color Scheme: Automatic / Light / Dark, Accent Theme circles, Horizontal & Vertical HUD Window sizing sliders).
    3. **Shortcuts** (Keybinding Editor launcher, JSON config file open, Local config auto-detection, Import file).
- **Appearance Mode Support (Dark, Light, Automatic)**:
  - Add `colorSchemeMode` setting:
    - `Automatic` (follows macOS system dark/light mode)
    - `Dark` (dark glass HUD + dark aqua windows)
    - `Light` (clean bright glass HUD + aqua light windows)
  - Applies reactively across:
    - The floating HUD window (`HUDView`).
    - The Settings window (`SettingsView`).
    - The Keybinding Editor window (`KeybindingEditorView`).

### Non-Goals
- Per-application theme overrides (theme applies globally to KeyHUD).

### Anti-Goals
- Inconsistent windows where Settings is bright white while the HUD is locked in dark mode.

---

## 3. Architecture & Data Model

### ColorSchemeMode Enum
```swift
enum ColorSchemeMode: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var appearance: NSAppearance? {
        switch self {
        case .automatic: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

### Settings Tab Enum
```swift
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .shortcuts: return "command"
        }
    }
}
```
