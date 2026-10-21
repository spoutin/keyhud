# KeyHUD

> **Instant, native floating shortcut cheatsheet & hotkey HUD for macOS, Ghostty, AeroSpace, Neovim, and CLI/TUI tools.**

KeyHUD gives you lightning-fast (<5ms), at-a-glance visibility into keyboard shortcuts across your active application, Ghostty terminal profiles, and system-level tiling window managers.

---

## Features

- **⚡ Sub-5ms Activation**: Pre-warmed resident floating panel with instant open/close latency and zero main-thread hitching.
- **🖥️ Context-Aware Cheatsheets**: Automatically scans native macOS menu bars while indexing custom shortcuts for Ghostty, AeroSpace, Neovim, and CLI tools.
- **🔍 Universal Command Palette (Paletro-Style)**: Index and search every clickable menu item and execute actions directly via Accessibility APIs (`Enter` or mouse-click).
- **⚠️ Real-Time Hotkey Conflict Detection**: Live duplicate detection across app-internal shortcuts and global collisions (AeroSpace, macOS system, KeyHUD). Includes an interactive **Conflict Summary Banner** and one-click isolation filter.
- **🧭 Interactive Breadcrumbs & 2D Arrow Navigation**: Navigate deep tool sub-profiles (e.g. `Ghostty` → `Neovim` → `Splits`) with visual breadcrumbs and hierarchical `Esc`-to-go-back.
- **⭐ Bookmarks & Favorites**: Pin your most-used commands to a dedicated `⭐ Favorites` column.
- **⌨️ Multi-Key Sequence Recorder**: Record Vim-like sequences (e.g. `sgh`, `gd`, `ciw`) and physical `Esc`/`Return` keys with full event swallowing and mouse-click confirmation.
- **🎨 Customization & Appearance**: Dark/Light modes, 5 accent color themes, optional high-contrast Zebra striping, and screen-percentage sizing.
- **📤 Markdown Cheatsheet Export**: Export formatted cheatsheets to the clipboard or save directly to Documents.

---

## Installation

### Via Homebrew (Recommended)

Install via the official `spoutin/tap`:

```bash
brew install --cask spoutin/tap/keyhud
```

Or tap the repository first:

```bash
brew tap spoutin/tap
brew install --cask keyhud
```

To update in the future:

```bash
brew upgrade keyhud
```

---

### Manual Download

1. Download the latest `KeyHUD-x.x.x.dmg` from [GitHub Releases](https://github.com/spoutin/keyhud/releases).
2. Drag `KeyHUD.app` into your `/Applications` folder.
3. Open Terminal and remove the quarantine attribute (only needed on initial download):
   ```bash
   xattr -cr /Applications/KeyHUD.app
   ```
4. Launch `KeyHUD` and grant **Accessibility** permission in macOS System Settings when prompted.

---

## Default Activation Shortcuts

| Trigger | Description |
|---|---|
| `⌘⇧/` (or `⌘⇧?`) | Global instant toggle hotkey |
| **Double-Tap ⌘ & Hold** | Quick hold-peek HUD overlay (configurable in Settings) |
| **Menu Bar Icon** | Click the `⌘` icon in the menu bar to toggle HUD, Settings, or the Keybinding Editor |

---

## Configuration & Keybindings

Custom shortcuts are stored in JSON at:
```bash
~/.config/keyhud/custom_shortcuts.json
```

Open Settings or the Keybinding Editor anytime via:
- Menu Bar icon → **Edit Keybindings...** (or press `⌘K` in Settings)
- In the HUD header → Click the **Pencil icon** (`Edit Shortcuts`)

---

## Building from Source

KeyHUD is built as a lightweight, single-file native Swift application with zero external framework dependencies:

```bash
# Clone the repository
git clone https://github.com/spoutin/keyhud.git
cd keyhud

# Build and install to /Applications/KeyHUD.app
./build.sh
```

---

## License

MIT © [spoutin](https://github.com/spoutin)
