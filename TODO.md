# KeyHUD Roadmap & TODO

## 🎯 High Priority

- [x] **Click-to-Execute Actions**
  - [x] For Native Mac Apps: Call `AXUIElementPerformAction(kAXPressAction)` on click to trigger the menu action in the target app.
  - [x] For Terminal / Custom Shortcuts: Synthesize and post `CGEvent` keystrokes to the target app (Ghostty) on click.
  - [x] Automatically close/hide HUD upon executing an action.
  - [x] Press `Enter` in search bar to execute the first matched shortcut immediately.

- [x] **Import Keybindings & Configuration Sync**
  - [x] Import shortcuts file via native open dialog (supports both KeyHUD `.json` and KeyClu `.keyclu` formats).
  - [x] Auto-Detect local configurations: parses `~/.config/herdr/config.toml`, `~/.config/zsh/`, and `~/.config/nvim/lua/config/keymaps.lua` and syncs them automatically into `custom_shortcuts.json`.
  - [x] Menu bar items and Settings buttons for Import and Auto-Detect.

- [x] **Keyboard Navigation in Search**
  - [x] Enable `Up` / `Down` arrow keys to highlight items in search results.
  - [x] Visual selection glow, border, and inverted contrast badge on active item.
  - [x] Press `Enter` to execute the highlighted shortcut immediately.

- [ ] **Visual Polish & Accent Coloring**
  - [ ] Accent color picker in Settings (Cyan, Catppuccin Blue, Mauve, Neon Green, Amber).
  - [ ] Row hover glow effect (smooth mouse-over illumination).
  - [ ] Zebra striping toggle in Settings for easier wide scanning.
  - [ ] Contrast-styled badge pills for modifiers (`⌃`, `⌥`, `⇧`, `⌘`).

---

## 🚀 Medium Priority

- [ ] **Command Hold Duration Slider**
  - [ ] Add slider in Settings to adjust `Command` hold delay (e.g. 0.2s - 0.8s).
  - [ ] Option to disable hold-to-activate and rely exclusively on the `Cmd+Shift+/` hotkey.

- [ ] **Bookmarks & Favorites**
  - [ ] Star icon next to shortcuts to mark them as favorites.
  - [ ] Pinned "Favorites" section or top-of-column highlighting for bookmarked items.

- [ ] **Persistent / Pin Mode**
  - [ ] Pin toggle button in the header so the HUD stays floating while working (ideal for multi-monitor setups).

---

## 📦 Low Priority / Nice-to-Have

- [ ] **Export to Markdown**
  - [ ] Button in header to export the current cheatsheet as a formatted `.md` file in `~/Documents`.

- [ ] **Launch at Login**
  - [ ] Toggle in Settings to automatically launch KeyHUD when logging into macOS.
