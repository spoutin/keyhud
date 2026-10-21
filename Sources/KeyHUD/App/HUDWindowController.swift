import SwiftUI
import AppKit

// MARK: - Key-Capable Resizable Floating Panel

class KeyHUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - HUD Window Controller

class HUDWindowController: NSWindowController {
    static let shared = HUDWindowController()
    private var eventMonitor: Any?
    private let searchState = SearchState()
    private let viewModel = HUDViewModel()
    private var currentTargetApp: NSRunningApplication?

    init() {
        let panel = KeyHUDPanel(
            contentRect: NSRect(x: 100, y: 100, width: 900, height: 600),
            styleMask: [.titled, .fullSizeContentView, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.animationBehavior = .utilityWindow
        panel.minSize = NSSize(width: 860, height: 520)

        super.init(window: panel)

        let hudView = HUDView(
            viewModel: viewModel,
            onExecute: { [weak self] item in
                ActionExecutor.shared.execute(item: item, targetApp: self?.currentTargetApp)
            },
            onDismiss: { [weak self] in
                self?.hide()
            },
            searchState: searchState
        )
        panel.contentView = NSHostingView(rootView: hudView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func targetScreen() -> NSScreen {
        let mouseLoc = NSEvent.mouseLocation
        if let mouseScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) {
            return mouseScreen
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    func applyScreenPercentageFrame(groups: [ShortcutGroup]? = nil) {
        guard let window = window else { return }
        let screen = targetScreen()
        let visible = screen.visibleFrame
        let settings = AppSettings.shared

        // Header requires ~840-860pt to comfortably display app dropdown, search bar, and 6 action buttons without clipping
        let minW: CGFloat = min(visible.width * 0.95, 860.0)
        // Minimum height of 520pt ensures at least 9-10 rows are visible without aggressive scrolling
        let minH: CGFloat = min(visible.height * 0.90, 520.0)

        let maxWPercent = max(35.0, min(100.0, settings.widthPercent))
        let maxHPercent = max(35.0, min(100.0, settings.heightPercent))

        let maxAllowedWidth = max(minW, visible.width * (maxWPercent / 100.0))
        let maxAllowedHeight = max(minH, visible.height * (maxHPercent / 100.0))

        let activeGroups = groups ?? viewModel.groups
        let fittedWidth: CGFloat
        let fittedHeight: CGFloat

        if activeGroups.isEmpty {
            fittedWidth = minW
            fittedHeight = max(minH, maxAllowedHeight * 0.75)
        } else {
            let colCount = CGFloat(max(1, min(activeGroups.count, 6)))
            let colWidth: CGFloat = 265.0
            let hPadding: CGFloat = 80.0
            let contentWidth = colCount * colWidth + hPadding

            let maxItems = activeGroups.map { $0.items.count }.max() ?? 0
            let rowH: CGFloat = 34.0
            let headerH: CGFloat = 40.0
            let chromeH: CGFloat = 180.0 // Header toolbar (56) + bottom legend bar (38) + GeometryReader margins (36) + card padding/header (50)
            let contentHeight = headerH + (CGFloat(maxItems) * rowH) + chromeH

            fittedWidth = max(minW, min(maxAllowedWidth, contentWidth))
            fittedHeight = max(minH, min(maxAllowedHeight, contentHeight))
        }

        let originX = visible.origin.x + (visible.width - fittedWidth) / 2.0
        let originY = visible.origin.y + (visible.height - fittedHeight) / 2.0

        let targetFrame = NSRect(x: originX, y: originY, width: fittedWidth, height: fittedHeight)
        window.setFrame(targetFrame, display: true, animate: window.isVisible)
    }

    private func resolveTargetApp(_ passedApp: NSRunningApplication? = nil) -> NSRunningApplication? {
        if let p = passedApp, p.bundleIdentifier != Bundle.main.bundleIdentifier && p.bundleIdentifier != "com.apple.loginwindow" {
            return p
        }

        // 1. macOS frontmost application (< 3ms)
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier &&
           front.bundleIdentifier != "com.apple.loginwindow" {
            return front
        }

        // 2. Menu bar owning application
        if let menuBarApp = NSWorkspace.shared.menuBarOwningApplication,
           menuBarApp.bundleIdentifier != Bundle.main.bundleIdentifier &&
           menuBarApp.bundleIdentifier != "com.apple.loginwindow" {
            return menuBarApp
        }

        // 3. Fallback to active regular app
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.activationPolicy == .regular &&
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            $0.bundleIdentifier != "com.apple.loginwindow" &&
            $0.isActive
        }) ?? NSWorkspace.shared.runningApplications.first(where: {
            $0.activationPolicy == .regular &&
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            $0.bundleIdentifier != "com.apple.loginwindow"
        })
    }

    func toggle(targetApp: NSRunningApplication? = nil) {
        guard let window = window else { return }
        if window.isVisible {
            hide()
        } else {
            show(for: targetApp)
        }
    }

    func show(for app: NSRunningApplication? = nil) {
        guard let window = window else { return }
        let target = resolveTargetApp(app)
        guard let validApp = target else { return }

        currentTargetApp = validApp
        searchState.query = ""
        searchState.clearHistory()
        searchState.selectedScope = .activeApp
        let defaultScope = SearchScope(rawValue: AppSettings.shared.defaultSearchScope) ?? .current
        searchState.activeSearchScope = defaultScope

        let bundleID = validApp.bundleIdentifier ?? ""
        let appName = validApp.localizedName ?? "Application"
        let icon = validApp.icon

        let groups: [ShortcutGroup]
        if bundleID == "com.mitchellh.ghostty" {
            groups = CustomShortcutsManager.shared.groups(for: bundleID) ?? []
        } else {
            let scanned = MenuScanner.scan(app: validApp)
            if let customGroups = CustomShortcutsManager.shared.groups(for: bundleID) {
                groups = customGroups + scanned
            } else {
                groups = scanned
            }
        }

        viewModel.appName = appName
        viewModel.bundleID = bundleID
        viewModel.appIcon = icon
        viewModel.groups = groups

        applyScreenPercentageFrame(groups: groups)
        AppSettings.shared.updateWindowsAppearance()

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if event.keyCode == 53 { // Esc
                if !self.searchState.query.isEmpty {
                    self.searchState.query = ""
                } else if self.searchState.canGoBack {
                    _ = self.searchState.popScope()
                } else if AppSettings.shared.isPinned {
                    AppSettings.shared.isPinned = false
                } else {
                    self.hide()
                }
                return nil
            }
            return event
        }
    }

    func hide() {
        window?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
