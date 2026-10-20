# Launch at Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a "Launch at Login" setting in the General tab of Settings using `SMAppService` with a fallback LaunchAgent plist.

**Architecture:** Create `LaunchAtLoginManager` to manage `SMAppService.mainApp` registration and `~/Library/LaunchAgents/com.ablack.KeyHUD.plist`. Add a clean toggle in `SettingsView` (General tab) under `AppSettings.launchAtLogin`.

**Tech Stack:** Swift 6, AppKit, SwiftUI, ServiceManagement.

**Spec:** `docs/superpowers/specs/2026-10-20-launch-at-login-design.md`

## Global Constraints
- Pure Swift 6 + AppKit + SwiftUI compiled with standalone `swiftc` via `/Users/ablack/.config/keyhud/build.sh`.
- No third-party package dependencies.
- Maintain ad-hoc signing with designated requirement `=designated => identifier "com.ablack.KeyHUD"`.

## Review Focus
1. Toggling on successfully writes LaunchAgent / registers service.
2. Toggling off cleans up registration and deletes LaunchAgent plist.
3. Does not crash if `~/Library/LaunchAgents` directory does not exist yet (creates intermediate directories).

---

### Task 1: Implement `LaunchAtLoginManager` and Add Toggle in Settings

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_launch_login.swift`

**Interfaces:**
- Produces: `LaunchAtLoginManager.shared.isEnabled: Bool`
- Produces: `LaunchAtLoginManager.shared.setEnabled(_: Bool) -> Bool`

- [ ] **Step 1: Write test script `/tmp/test_launch_login.swift`**
Validate that enabling creates the plist / registers, and disabling removes it cleanly.

- [ ] **Step 2: Run test script to verify failure / initial state**
Run: `swift /tmp/test_launch_login.swift`

- [ ] **Step 3: Implement `LaunchAtLoginManager` in `KeyHUD.swift`**
Implement manager with `SMAppService` and user `LaunchAgents` fallback.
Add toggle row in `SettingsView` (under General tab, above Pin Mode).

- [ ] **Step 4: Build and verify with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: add Launch at Login support and Settings toggle"
```

---

### Task 2: Verification and TODO.md Update

**Files:**
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Mark Launch at Login completed in `TODO.md`**

- [ ] **Step 2: Build, sign, and relaunch `/Applications/KeyHUD.app`**
Run:
```bash
/Users/ablack/.config/keyhud/build.sh
killall KeyHUD || true
open /Applications/KeyHUD.app
```

- [ ] **Step 3: Commit**
```bash
git add TODO.md
git commit -m "docs: mark Launch at Login / Boot task as completed in TODO"
```
