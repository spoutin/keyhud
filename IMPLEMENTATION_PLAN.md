# KeyHUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS shortcuts HUD app (`KeyHUD`) that replicates KeyClu's native menu scanning for standard apps, but displays a custom 5-column layout for Ghostty/terminal with instant search.

**Architecture:** A standalone lightweight Swift / SwiftUI macOS menu bar app. It monitors global hotkeys (Command hold or `Cmd+Shift+/`), checks `NSWorkspace.frontmostApplication`, loads custom JSON overrides for specified apps (e.g. `com.mitchellh.ghostty`), or queries `AXUIElement` accessibility menus for all other Mac apps. It presents an `NSPanel` floating HUD with a real-time search filter and multi-column grid.

**Tech Stack:** Swift 6, AppKit, SwiftUI, ApplicationServices (Accessibility API). Zero external dependencies.

---

## Global Constraints

- Native macOS (Apple Silicon arm64, macOS 14+ / 15+ compatible).
- App bundle installed at `/Applications/KeyHUD.app`.
- Custom configuration stored at `~/.config/keyhud/custom_shortcuts.json`.
- Runs as an agent (`LSUIElement = true`) with a menu bar item for Settings/Quit.
- Esc key or releasing trigger dismisses the HUD.

---

## Tasks

### Task 1: Create Configuration File & Models
- Define `~/.config/keyhud/custom_shortcuts.json` containing the exact 5-column shortcuts:
  - `Ghostty & Herdr`
  - `Zsh & Shell`
  - `Neovim: Movements & Jumps`
  - `Neovim: Windows & Splits`
  - `Neovim: Edits & Leader`
- Define the Swift data models (`ShortcutItem`, `ShortcutGroup`, `AppShortcutsConfig`).

### Task 2: Build the Accessibility Menu Scanner
- Implement `MenuScanner`: queries `AXUIElement` for the frontmost application.
- Extracts menu titles, command characters, and modifier bitmasks (`⌘`, `⌥`, `⌃`, `⇧`).
- Groups items by top-level menu (`File`, `Edit`, `View`, etc.).

### Task 3: Build the SwiftUI Floating HUD
- Create `HUDView`:
  - Instant search bar auto-focused on appear.
  - Horizontal scrolling / multi-column grid displaying all groups.
  - Modifiers formatted as Apple badges (`⌃`, `⌥`, `⌘`, `⇧`).
  - Search filtering across all column titles and key combos simultaneously.
- Create `HUDPanel`: `NSPanel` with `.nonactivatingPanel`, floating above all spaces.

### Task 4: Implement Trigger Listener & App Lifecycle
- Implement `HotKeyManager`:
  - Global listener for `Cmd+Shift+/` (or double-tap / hold Command).
  - Status item in the menu bar with Quit and Open Config actions.
- Connect everything in `AppDelegate`.

### Task 5: Package, Compile & Validate
- Create `build.sh` script to compile with `swiftc`, build `KeyHUD.app` bundle with `Info.plist`, and codesign ad-hoc.
- Launch `KeyHUD.app` and verify in Ghostty (custom 5 columns) and in standard apps (native menu shortcuts).
