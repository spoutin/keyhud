# CLI/TUI Tools Cheatsheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add cheatsheets for K9s, Lazygit, Atuin, and VisiData to Ghostty's custom shortcuts configuration, and default them to the sub-menu.

**Architecture:** Update `custom_shortcuts.json` with the 4 tool categories. Update `CustomShortcutsManager.autoDetectLocalConfigs()` in `KeyHUD.swift` to detect/sync these tools. Set default visibility for these categories to sub-menu only in `AppSettings`.

**Tech Stack:** JSON, Swift 6.

**Spec:** `docs/superpowers/specs/2026-10-20-cli-tui-cheatsheets-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.

## Review Focus
1. All 4 categories appear under `Terminal Tools` in Ghostty's scope dropdown.
2. None of the 4 tools clutter Ghostty's main view unless the user enables them in Settings.
3. Key tokens render cleanly with appropriate colors in both HUD and Editor.

---

### Task 1: Update `custom_shortcuts.json` and Auto-Detector in `KeyHUD.swift`

**Files:**
- Modify: `/Users/ablack/.config/keyhud/custom_shortcuts.json`
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

- [ ] **Step 1: Add K9s, Lazygit, Atuin, and VisiData categories to `custom_shortcuts.json`**
Add the structured shortcut dictionaries under `"com.mitchellh.ghostty"`.

- [ ] **Step 2: Update `autoDetectLocalConfigs()` in `KeyHUD.swift`**
Detect `~/.config/k9s`, `~/.config/lazygit`, `~/.config/atuin`, and install/sync their categories.

- [ ] **Step 3: Set default hidden-from-main status for new TUI tools in `AppSettings`**
Ensure that `"K9s: Kubernetes"`, `"Lazygit: Git TUI"`, `"Atuin: Shell History"`, and `"VisiData: Data Tables"` are in `ghosttyHiddenCategories` by default.

- [ ] **Step 4: Build and test compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add custom_shortcuts.json KeyHUD.swift
git commit -m "feat: add cheatsheets for K9s, Lazygit, Atuin, and VisiData to Ghostty"
```

---

### Task 2: Verification and Relaunch

**Files:**
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 2: Verify in Terminal Tools sub-menu and Settings**

- [ ] **Step 3: Commit**
```bash
git add TODO.md docs/
git commit -m "docs: complete CLI/TUI tools cheatsheet task"
```
