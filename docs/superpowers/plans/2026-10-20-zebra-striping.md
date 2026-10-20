# Zebra Striping (Alternating Row Colors) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a configurable "Zebra Striping" (alternating row background) toggle in Settings under the Appearance tab that enhances readability across wide shortcut tables.

**Architecture:**
- Add `@Published var zebraStriping: Bool` in `AppSettings` backed by `UserDefaults` with key `"zebraStriping"`.
- Add a clean Toggle switch in `SettingsView` under the **Appearance** tab.
- Pass `isOddRow: Bool` and `zebraEnabled: Bool` (or check `AppSettings.shared.zebraStriping`) in `ShortcutRow` to render alternating row tints (`Color.white.opacity(0.06)` vs `Color.white.opacity(0.02)`) while preserving selected, hovered, and bookmarked states.
- Update `TODO.md` to check off the zebra striping roadmap item.

**Tech Stack:** Swift, SwiftUI, AppKit.

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros in `KeyHUD.swift`.

## Review Focus
1. When zebra striping is toggled ON, odd rows have a subtle background tint (`Color.white.opacity(0.06)`), and even rows have standard subtle background (`Color.white.opacity(0.02)` or clear).
2. When zebra striping is toggled OFF, all unselected rows have the default uniform background (`Color.white.opacity(0.03)`).
3. Selected rows, hovered rows, and bookmarked rows still take visual precedence over the zebra background tint.
4. The setting persists across app restarts in `UserDefaults.standard`.
5. The toggle appears cleanly in Settings -> Appearance.

---

### Task 1: Add Zebra Striping Configuration to AppSettings & SettingsView

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_zebra_settings.swift`

**Interfaces:**
- Produces: `AppSettings.zebraStriping: Bool`

- [ ] **Step 1: Write test script `/tmp/test_zebra_settings.swift`**
Verify `zebraStriping` boolean defaults to `false` or saved value in `UserDefaults`.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_zebra_settings.swift`

- [ ] **Step 3: Implement `zebraStriping` in `AppSettings`**
Add `@Published var zebraStriping: Bool` with `didSet` persisting to `UserDefaults.standard.set(zebraStriping, forKey: "zebraStriping")`, and initialize it in `init()`.

- [ ] **Step 4: Add Toggle in `SettingsView` appearance tab**
Add a dedicated section in `appearanceTabView`:
```swift
VStack(alignment: .leading, spacing: 10) {
    Text("ROW CONTRAST & SCANNING")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.secondary)

    Toggle(isOn: $settings.zebraStriping) {
        VStack(alignment: .leading, spacing: 2) {
            Text("Enable Zebra Striping")
                .font(.system(size: 13, weight: .medium))
            Text("Alternates row shading across columns for easier horizontal scanning.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    .toggleStyle(SwitchToggleStyle(tint: settings.currentAccentColor))
}
.padding(14)
.background(Color(NSColor.controlBackgroundColor))
.cornerRadius(8)
```

- [ ] **Step 5: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

---

### Task 2: Apply Alternating Shading in ShortcutRow

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Update `ShortcutRow` to accept row index / isOddRow**
Pass `isOddRow: (itemIndex % 2 != 0)` into `ShortcutRow`.
Calculate default background:
```swift
let defaultBg: Color = {
    if !settings.zebraStriping {
        return Color.white.opacity(0.03)
    }
    return isOddRow ? Color.white.opacity(0.065) : Color.white.opacity(0.015)
}()
```
Background fill:
```swift
isSelected ? accentColor.opacity(0.25) : (isBookmarked ? Color.yellow.opacity(0.06) : (isHovered ? Color.white.opacity(0.08) : defaultBg))
```

- [ ] **Step 2: Pass itemIndex into `ShortcutRow` call site**
In `HUDView`, pass `isOddRow: (itemIndex % 2 != 0)`.

- [ ] **Step 3: Update `TODO.md`**
Mark `- [x] Zebra striping toggle in Settings for easier wide scanning.` as completed.

- [ ] **Step 4: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: add zebra striping setting and alternating row shading"
```
