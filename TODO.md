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
  - [x] Enable `Up` / `Down` arrow keys to navigate rows within columns.
  - [x] Enable `Left` / `Right` arrow keys to jump between columns.
  - [x] Visual selection glow, border, and inverted contrast badge on active item.
  - [x] Press `Enter` to execute the highlighted shortcut immediately.

- [x] **Visual Polish & Accent Coloring**
  - [x] Accent color picker in Settings (Cyan, Catppuccin Sapphire Blue, Mauve, Neon Green, Amber).
  - [x] Row hover glow effect (smooth mouse-over illumination).
  - [x] Reactive real-time theme updating across HUD columns, badges, borders, and settings.
  - [ ] Zebra striping toggle in Settings for easier wide scanning.

---

## 🎯 Next Features

- [x] **Per-Application Keybinding Viewer & Editor**
  - [x] Dedicated resizable Keybinding Editor window accessible from HUD header (`square.and.pencil`), Settings (`Manage Keybindings...`), and menu bar tray.
  - [x] App selector dropdown with ability to add new applications by bundle ID.
  - [x] Category management: add, delete, and browse categories per application.
  - [x] Inline shortcut editing: edit title and key combo inline with instant delete.
  - [x] Quick-insert modifier toolbar pills (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`).
  - [x] In-memory document staging with dirty tracking, "Save Changes", and "Revert" actions.
  - [x] Merges custom shortcuts alongside native app menus for non-terminal Mac apps.

- [ ] **Global Shortcuts Section (System-wide, similar to KeyClu)**
  - [ ] Dedicated "Global" column/category visible across all applications (macOS system shortcuts: Window Tiling, Screenshots, Mission Control, Spotlight, App Switching).
  - [ ] Customizable global shortcuts stored under a `"global"` entry in `custom_shortcuts.json`.
  - [ ] Toggle in Settings to show or hide the Global shortcuts column.

---

## 🚀 Medium Priority

- [x] **Persistent / Pin Mode**
  - [x] Pin toggle button in the header so the HUD stays floating while working (ideal for multi-monitor setups).
  - [x] Clicking or pressing Enter to execute shortcuts dispatches to target app while keeping HUD open.
  - [x] Persistent Pin Mode toggle in Settings.

- [x] **Command Hold Duration Slider & Trigger Sensitivity**
  - [x] Adjustable Command hold duration slider in Settings (150ms - 800ms).
  - [x] Shortcut-Only mode (`⌘⇧/ Only`) to disable all Command tap/hold modifier interception.
  - [x] Real-time millisecond readout on the slider.

- [ ] **Bookmarks & Favorites**
  - [ ] Star icon next to shortcuts to mark them as favorites.
  - [ ] Pinned "Favorites" section or top-of-column highlighting for bookmarked items.

---

## 📦 Low Priority / Nice-to-Have

- [ ] **Export to Markdown**
  - [ ] Button in header to export the current cheatsheet as a formatted `.md` file in `~/Documents`.

- [ ] **Launch at Login**
  - [ ] Toggle in Settings to automatically launch KeyHUD when logging into macOS.
