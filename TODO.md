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

- [x] **Global Shortcuts & Scope Switcher (AeroSpace, macOS System, App-Specific)**
  - [x] Header scope switcher dropdown with dedicated icons (`[App Icon]` Active App, `[macwindow.on.rectangle]` AeroSpace Tiling, `[apple.logo]` macOS System).
  - [x] AeroSpace config parser (`~/.config/aerospace/aerospace.toml`) auto-categorizing window focus, movement, workspaces, and service mode bindings.
  - [x] Built-in comprehensive macOS System cheatsheet (App switching, screenshots, Mission Control & Spaces, system accessibility).
  - [x] Instant reactive column grid update without closing or dismissing the HUD.
  - [x] Global shortcut execution via system-level event dispatch.

- [x] **Unified Modifier Colors & Icon Scheme in Settings & Keybinding Editor**
  - [x] Update the modifier insertion pills in the Keybinding Editor (`⌃`, `⌥`, `⇧`, `⌘`, `Space`, `Esc`) to match the HUD's vibrant individual color palette and symbol styling (`⌘` Blue, `⇧` Green, `⌥` Orange, `⌃` Purple, `⎋` Coral/Rose, `␣` Cyan).
  - [x] Show real-time colored tokenized badge previews in the shortcut rows within the Keybinding Editor instead of a plain text field alone.
  - [x] Add the modifier legend bar to the Keybinding Editor tab in Settings for consistent quick reference.


- [x] **Shell & TUI Application Cheatsheets with Ghostty Sub-Menu & Main Visibility Controls**
  - [x] Support distinct CLI/TUI application profiles (e.g. `Neovim`, `Ghostty/Herdr`, `Zsh`, `lazygit`, `yazi`, `tmux/zellij`, `k9s`).
  - [x] Add a sub-menu / scope filter under Ghostty in the HUD header dropdown (e.g. `Ghostty (Main)`, individual tools under `Terminal Tools`) so individual TUI cheatsheets can be viewed in isolation.
  - [x] Add configuration controls in Settings (under Shortcuts & Editor) to choose which TUI tools appear on the "Main" Ghostty page versus remaining exclusively in the sub-menu.
  - [x] Allow adding custom CLI/TUI tool categories and keybindings in the Keybinding Editor under terminal tools.

- [x] **Adjustable Search Scope (Current, Current + Sub-tools, All / Global)**
  - [x] Search scope modes (`Current View`, `Current + Sub-tools`, `All / Global`).
  - [x] Interactive scope selector button beside search textfield in the HUD view.
  - [x] Configurable default search scope setting in Settings under General tab.
  - [x] Full 2D navigation and execute across all matched multi-scope shortcut results.

- [x] **Non-Active App Selector with Distinct Dividers & Universal Fuzzy Matcher**
  - [x] Top-left Scope Dropdown displays clear section dividers: `ACTIVE CONTEXT`, `GLOBAL TOOLS`, and `OTHER RUNNING APPS`.
  - [x] Dynamically enumerates all other running regular macOS applications with their native icons and localized names.
  - [x] Selecting any running app immediately loads and renders its cheatsheet without activating the app or switching workspaces.
  - [x] Universal `FuzzyMatcher` engine powers the search bar and filter matching across both titles and keys.

- [x] **Header Breadcrumb Trail & Hierarchical Esc-to-Go-Back Navigation**
  - [x] Push/pop navigation history stack in `SearchState`.
  - [x] Interactive header breadcrumb trail showing parent segments with jump-back links.
  - [x] Hierarchical Esc behavior: clears query first, pops navigation history second, and closes the HUD at root.

- [x] **Instant HUD Display & Performance Optimization (< 10ms)**
  - [x] Reusable resident `NSHostingView` backed by observable `HUDViewModel` to eliminate view teardown/rebuild.
  - [x] Pre-cached `RunningAppsTracker` with notification-based updates, avoiding disk/icon lookups during render.
  - [x] In-memory caching for `MenuScanner` to eliminate repeated Accessibility tree crawling.
  - [x] Removed blocking `/opt/homebrew/bin/aerospace` subprocess execution from main-thread open path.
  - [x] Zero-latency Carbon `RegisterEventHotKey` for instantaneous `⌘⇧/` triggering at WindowServer level.

- [x] **Dynamic Shrink-to-Fit Window Sizing with Configurable Ceiling**
  - [x] Settings width and height percentages act as maximum allowed ceiling.
  - [x] HUD window automatically shrinks down to tightly fit smaller cheatsheets and sub-tools without empty dead space.
  - [x] Strict minimum size floor (520 × 360 pt) ensures search bar and legend chrome always fit comfortably.
  - [x] Dynamic animated resize when switching scopes or sub-tools.

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

- [x] **Bookmarks & Favorites**
  - [x] Star icon next to shortcuts to mark them as favorites (subtle outline on hover, vibrant filled gold star when bookmarked).
  - [x] Dedicated "⭐ Favorites" column pinned at the top-left of the HUD for the active app/tool whenever favorites exist.
  - [x] In-place gold star badge and delicate accent tint on bookmarked items in their original categories.
  - [x] Unstarring items automatically updates the UI and smoothly collapses the favorites group when empty.
  - [x] Persistent storage in `UserDefaults` across restarts per scope / app.

---

## 📦 Low Priority / Nice-to-Have

- [ ] **Export to Markdown**
  - [ ] Button in header to export the current cheatsheet as a formatted `.md` file in `~/Documents`.

- [x] **Launch at Login / Boot (Start on Boot)**
  - [x] Implement `SMAppService.mainApp` (macOS 13+) API to cleanly register `/Applications/KeyHUD.app` as a login item without legacy AppleScript or helper daemons.
  - [x] Provide fallback LaunchAgent plist generation (`~/Library/LaunchAgents/com.ablack.KeyHUD.plist`) if `SMAppService` status requires user approval or older subsystem fallback.
  - [x] Add a prominent "Launch at Login" toggle switch in Settings under the **General** tab.
  - [x] Sync the toggle state with the real-time system registration status (`SMAppService.mainApp.status == .enabled`).
