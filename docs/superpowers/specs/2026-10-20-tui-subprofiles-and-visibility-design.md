# Design Specification: Shell & TUI Application Cheatsheets with Ghostty Sub-Menu & Main Visibility Controls

## 1. Intent & Purpose

Ghostty users frequently switch between terminal CLI/TUI tools (like Neovim, Herdr/tmux, Zsh, lazygit, yazi). Currently, all categories under Ghostty are combined into a single wide multi-column layout. When many TUI tools are added, the main cheatsheet can become overwhelming.

This feature allows:
1. Sub-profiles grouped under Ghostty (e.g. `Ghostty & Herdr`, `Neovim`, `Zsh`, `lazygit`, etc.).
2. In the HUD header Scope dropdown, when Ghostty is active, users can view Ghostty as a whole (`Main`), or isolate a specific tool (`Neovim`, `Zsh`, etc.).
3. In **Settings ➔ Shortcuts & Editor**, users have toggle switches (`[✓] Show on Main Cheatsheet`) next to each category to decide which tools appear on Ghostty's main combined overview.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Per-Category Visibility on Main**:
  - Store a list of enabled main categories in `AppSettings` (defaulting to all existing categories being enabled).
  - In Settings under the **Shortcuts & Editor** tab, show a toggle switch `Show on Main Page` on each category card header for Ghostty.
  - Categories with the toggle disabled are hidden from the "Main" Ghostty cheatsheet, keeping it clean and focused.
- **HUD Scope Sub-Menu for Ghostty**:
  - In the Scope Dropdown in the HUD header, when Ghostty is active, show:
    - `[Terminal Icon] Ghostty (Main)`
    - `  └ 🌿 Ghostty & Herdr`
    - `  └ ⚡ Neovim`
    - `  └ 🐚 Zsh`
    - (and any custom added TUI sub-profiles)
  - Selecting an individual tool filters the HUD view down exclusively to that tool's shortcut columns.
- **Support Adding New TUI Tools**:
  - In the Keybinding Editor under Ghostty, users can add new categories (e.g., "lazygit", "yazi", "k9s") and toggle whether they appear on the main page.

### Non-Goals
- Auto-detecting process execution inside terminal shells (e.g., hooking into shell hooks to know if lazygit is currently in foreground; manual selection via the Scope dropdown gives instant, predictable control).

---

## 3. Architecture & Data Model

### AppSettings Updates
```swift
@Published var ghosttyHiddenMainCategories: [String] // Categories excluded from Main view
```

### HUD Scope Updates
```swift
enum HUDScope: Hashable, Identifiable {
    case activeApp
    case ghosttySubProfile(category: String)
    case aerospace
    case macos
}
```

When `selectedScope == .activeApp`:
- If `bundleID == "com.mitchellh.ghostty"`, filter out categories in `ghosttyHiddenMainCategories`.
When `selectedScope == .ghosttySubProfile(let category)`:
- Display only the groups belonging to `category`.
