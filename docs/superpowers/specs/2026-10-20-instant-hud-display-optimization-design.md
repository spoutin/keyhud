# Design Specification: Instant HUD Display & Performance Optimization

## 1. Intent & Purpose

KeyHUD currently experiences noticeable delay (~150ms to 250ms+) when triggered to open. This latency is caused by four synchronous main-thread bottlenecks and event delivery delays:
1. Spawning `/opt/homebrew/bin/aerospace` via synchronous `Process()` on the main thread (~65ms).
2. Synchronous recursive accessibility tree walk via `MenuScanner.scan` on the main thread (~25-100ms).
3. Synchronous enumeration of running applications and filesystem icon loading inside SwiftUI's `HUDView.body` layout pass (~30-50ms).
4. Destroying and re-creating `NSHostingView` on every single invocation of `show()` (~30-50ms).
5. Passive `NSEvent.addGlobalMonitorForEvents` for `⌘⇧/` hotkey instead of an active/low-latency system listener.

The goal of this optimization is to make the HUD window display **instantly (< 10ms)** upon trigger.

---

## 2. Architecture & Design

### 2.1 Fast Target App Resolution (0ms)
- `NSWorkspace.shared.frontmostApplication` executes in ~3ms.
- Avoid calling the AeroSpace CLI synchronously during window open.
- Only if AeroSpace is running and has focused a window from an app that differs from `frontmostApplication`, query it asynchronously or rely on `frontmostApplication` / `menuBarOwningApplication`, falling back seamlessly without blocking the UI thread.

### 2.2 Reusable Resident `NSHostingView` with Reactive `HUDViewModel`
- Instead of allocating a new `NSHostingView(rootView: hudView)` every time `show()` is called, initialize `NSHostingView` once when the panel is created.
- The hosting view wraps a root view backed by an observable `HUDViewModel` (or `SearchState`).
- Calling `show()` simply updates the observable properties on the view model (`bundleID`, `appName`, `appIcon`, `groups`) and calls `window.orderFrontRegardless()` / `window.makeKeyAndOrderFront()`. This eliminates AppKit view teardown/rebuild latency completely.

### 2.3 Pre-Cached Running Apps & Icons
- Introduce `RunningAppsTracker.shared`:
  - Maintains a cached array of `AppItem(bundleID, name, icon)`.
  - Populates once at launch in the background.
  - Subscribes to `NSWorkspace.didLaunchApplicationNotification` and `NSWorkspace.didTerminateApplicationNotification` to keep the cache updated with zero overhead during render passes.
  - `HUDView` reads from this memory cache directly, reducing view body evaluation time to < 0.5ms.

### 2.4 Cached / Asynchronous Menu Scanner
- Maintain an in-memory cache of scanned menus keyed by `bundleIdentifier`:
  `static var menuCache: [String: [ShortcutGroup]] = [:]`
- If an app's menu bar has already been scanned in this session, return it immediately from cache.
- When opening an app that is not yet cached:
  - If custom shortcuts exist for that app (e.g. Ghostty or configured apps), display them immediately.
  - If scanning is needed, run `MenuScanner.scan` on a background thread and update the view model's groups on completion, or show cached items instantly.

### 2.5 Instant Carbon HotKey for `⌘⇧/`
- Register `⌘⇧/` using Carbon `RegisterEventHotKey` (or active CGEventTap).
- Dispatches immediately at the window server layer without waiting for active app event queue drain.

---

## 3. Goals & Metrics
- **Window Display Time:** < 10ms from trigger event to visible pixel on screen.
- **Main Thread Work on Show:** Purely memory assignments and `orderFrontRegardless()`. Zero disk I/O, zero subprocesses, zero blocking accessibility IPC.
