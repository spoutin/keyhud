# Instant HUD Display & Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate main-thread blocking operations when KeyHUD triggers so the popup appears instantly (< 10ms).

**Architecture:** 
1. Create `RunningAppsTracker` with notification-based caching so `HUDView` never queries disk/icons during render.
2. Add menu bar caching to `MenuScanner` so apps are scanned once and served instantly from memory.
3. Replace synchronous AeroSpace CLI subprocess execution in `resolveTargetApp` with fast `frontmostApplication` / `menuBarOwningApplication` (3ms vs 65ms).
4. Migrate `HUDWindowController` to a resident `NSHostingView` backed by an observable view model instead of tearing down and recreating `NSHostingView` on every toggle.
5. Add Carbon HotKey registration for instant `⌘⇧/` triggering.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Carbon (`Carbon.HIToolbox`).

**Spec:** `docs/superpowers/specs/2026-10-20-instant-hud-display-optimization-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros (standalone `swiftc` compatibility).

## Review Focus
1. Window appears instantly on hotkey press (< 10ms) without frame drops.
2. AeroSpace workspace switching and floating HUD behavior remains rock solid.
3. Non-active running apps selector continues to show all running apps and icons correctly.
4. Menu shortcuts for native apps are correctly scanned and cached.
5. All tests and builds pass.

---

### Task 1: RunningAppsTracker & Menu Bar Caching

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Produces: `RunningAppsTracker.shared.runningApps: [RunningAppItem]`
- Produces: `MenuScanner.cachedScan(app: NSRunningApplication) -> [ShortcutGroup]`

- [ ] **Step 1: Implement `RunningAppsTracker`**
Create `struct RunningAppItem` and `class RunningAppsTracker` that caches running regular applications and their icons, refreshing via `NSWorkspace.didLaunchApplicationNotification` and `NSWorkspace.didTerminateApplicationNotification`.

- [ ] **Step 2: Add in-memory cache to `MenuScanner`**
Add `static var cache: [String: [ShortcutGroup]] = [:]` to `MenuScanner`. If `cache[bundleID]` exists, return it instantly; scan and store on first request.

- [ ] **Step 3: Update `HUDView` to read from `RunningAppsTracker`**
Replace lines 1778-1802 where `NSWorkspace.shared.runningApplications` and `app.icon` are repeatedly queried inside SwiftUI body with `RunningAppsTracker.shared.runningApps`.

- [ ] **Step 4: Verify compilation with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "perf: cache running applications and menu bar scans"
```

---

### Task 2: Eliminate Subprocess Blocking & Resident NSHostingView

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`

**Interfaces:**
- Produces: `HUDViewModel: ObservableObject`
- Produces: Non-blocking `resolveTargetApp`
- Produces: Resident `NSHostingView` created once in `HUDWindowController.init`

- [ ] **Step 1: Optimize `resolveTargetApp`**
Remove blocking `Process()` calls from the main-thread `resolveTargetApp` path. Use `NSWorkspace.shared.frontmostApplication` and `menuBarOwningApplication`, which resolve in < 3ms.

- [ ] **Step 2: Introduce `HUDViewModel` and resident `NSHostingView`**
Create `HUDViewModel: ObservableObject` holding `appName`, `bundleID`, `appIcon`, and `groups`.
In `HUDWindowController`:
Instantiate `NSHostingView(rootView: HUDContainerView(viewModel: ...))` once in `init(panel:)`.
In `show(for:)`: simply update `viewModel` and call `window.orderFrontRegardless()`.

- [ ] **Step 3: Verify build and measure latency**
Run `/Users/ablack/.config/keyhud/build.sh` and verify instant display.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift
git commit -m "perf: eliminate aerospace subprocess and reuse resident hosting view"
```

---

### Task 3: Carbon HotKey Registration & Verification

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Add Carbon HotKey registration for `⌘⇧/`**
Use `RegisterEventHotKey` with Carbon event handler so `⌘⇧/` triggers at kernel/WindowServer speed with 0ms delivery latency.

- [ ] **Step 2: Update `TODO.md`**
Record the performance optimizations and instant display in `TODO.md`.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: complete instant HUD display optimizations and Carbon hotkey"
```
