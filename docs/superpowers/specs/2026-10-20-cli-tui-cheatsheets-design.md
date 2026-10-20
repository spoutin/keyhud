# Design Specification: Local CLI/TUI Tools Cheatsheets (K9s, Lazygit, Atuin, VisiData)

## 1. Intent & Purpose

Users have several CLI/TUI tools installed on their system (`k9s`, `lazygit`, `atuin`, `visidata`) that they run from Ghostty. They need ready access to their keyboard shortcuts without cluttering the main Ghostty cheatsheet.

This feature adds curated, verified shortcuts for these 4 tools into `custom_shortcuts.json` under Ghostty and configures `ghosttyHiddenCategories` in `AppSettings` so they default to **Sub-menu Only** (accessible on-demand via the HUD Scope dropdown under `Terminal Tools` or via the Keybinding Editor).

---

## 2. Tools & Keybinding Sets

### 1. K9s: Kubernetes TUI (`K9s: Kubernetes`)
- `:pods` ➔ Pods View
- `:deploy` ➔ Deployments View
- `:svc` ➔ Services View
- `:ns` ➔ Switch Namespaces
- `:ctx` ➔ Switch Contexts
- `/` ➔ Filter Resources
- `Esc` ➔ Clear Filter / Back
- `d` ➔ Describe Resource
- `l` ➔ View Pod Logs
- `s` ➔ Shell Exec into Pod
- `e` ➔ Edit Resource YAML
- `w` ➔ Toggle Wrap Logs
- `⌃D` ➔ Delete Resource

### 2. Lazygit: Git Client (`Lazygit: Git TUI`)
- `1` ➔ Status Panel
- `2` ➔ Files Panel
- `3` ➔ Branches Panel
- `4` ➔ Commits Panel
- `5` ➔ Stash Panel
- `[` / `]` ➔ Previous / Next Tab
- `Space` ➔ Stage / Toggle File or Hunk
- `c` ➔ Commit Changes
- `A` ➔ Amend Commit
- `P` ➔ Push Remote
- `p` ➔ Pull Remote
- `b` ➔ Branch Menu
- `z` ➔ Undo Action

### 3. Atuin: Shell History (`Atuin: Shell History`)
- `⌃R` ➔ Interactive History Search
- `⌃E` ➔ Edit Search Query
- `Tab` ➔ Inspect Command Details
- `⌃O` ➔ Execute Command Immediately
- `⌃P` / `⌃N` ➔ Previous / Next History Result
- `⌥1` .. `⌥4` ➔ Filter (Global / Host / Session / Dir)

### 4. VisiData: Data Table TUI (`VisiData: Data Tables`)
- `q` ➔ Quit Sheet / Back
- `^` ➔ Set Column as Key
- `[` / `]` ➔ Sort Ascending / Descending
- `F` ➔ Frequency Summary Table
- `s` / `t` / `u` ➔ Select / Toggle / Unselect Row
- `"` ➔ Duplicate Selected Rows
- `⌃S` ➔ Save Sheet to File

---

## 3. Architecture & Default Configuration

- Update `custom_shortcuts.json` under `"com.mitchellh.ghostty"` with the 4 new categories.
- Update `AppSettings.init()`: if `ghosttyHiddenCategories` is not explicitly modified by the user, ensure new TUI categories default to hidden from the main view (only appearing in the sub-menu).
- Update `autoDetectLocalConfigs()` in `KeyHUD.swift` to automatically include these tools when scanning local configs.
