# Design Specification: Launch at Login (Start on Boot)

## 1. Intent & Purpose

Users want KeyHUD to be available immediately upon logging into their Mac without needing to manually launch the app each time. Since KeyHUD runs as an unobtrusive menu bar / accessory background agent (`LSUIElement = true`), starting on login allows global shortcut listening (`⌘⇧/`, double-tap Command) to be always accessible.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Dual Launch Registration**:
  - Primary: Modern `SMAppService.mainApp` API (macOS 13+).
  - Robust Fallback: User LaunchAgent plist (`~/Library/LaunchAgents/com.ablack.KeyHUD.plist`) targeting `/Applications/KeyHUD.app/Contents/MacOS/KeyHUD`.
- **Settings UI**:
  - Add a toggle switch inside the **General** tab in Settings:
    - Label: `Launch at Login`
    - Subtitle: `Automatically start KeyHUD in the background when logging into your Mac.`
  - Dynamically reflect current status on view appear and on toggle.
- **Persistence**:
  - Remember user choice in `AppSettings` / `UserDefaults` and reconcile with real-time launch agent / service state.

### Non-Goals
- Adding redundant menu items to the already concise menu bar tray.
- Requiring root/sudo privileges (user-level LaunchAgents or `SMAppService` are completely rootless).

---

## 3. Architecture & Data Model

### LaunchAtLoginManager
```swift
class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    let bundleID = "com.ablack.KeyHUD"
    let appPath = "/Applications/KeyHUD.app"

    @Published var isEnabled: Bool = false

    func refreshStatus()
    func setEnabled(_ enable: Bool) -> Bool
}
```
