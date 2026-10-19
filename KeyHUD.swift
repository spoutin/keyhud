import Cocoa
import SwiftUI
import ApplicationServices

// MARK: - Models

struct ShortcutItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let title: String
    let keys: String

    enum CodingKeys: String, CodingKey {
        case title, keys
    }
}

struct ShortcutGroup: Identifiable, Equatable {
    var id = UUID()
    let title: String
    let items: [ShortcutItem]
}

// MARK: - App Settings & Preferences

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var widthPercent: Double {
        didSet { UserDefaults.standard.set(widthPercent, forKey: "widthPercent") }
    }
    @Published var heightPercent: Double {
        didSet { UserDefaults.standard.set(heightPercent, forKey: "heightPercent") }
    }

    init() {
        let savedW = UserDefaults.standard.double(forKey: "widthPercent")
        self.widthPercent = (savedW >= 20 && savedW <= 100) ? savedW : 75.0

        let savedH = UserDefaults.standard.double(forKey: "heightPercent")
        self.heightPercent = (savedH >= 20 && savedH <= 100) ? savedH : 65.0
    }
}

// MARK: - Custom Shortcuts Manager

class CustomShortcutsManager {
    static let shared = CustomShortcutsManager()
    private let configPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        configPath = "\(home)/.config/keyhud/custom_shortcuts.json"
    }

    func groups(for bundleID: String) -> [ShortcutGroup]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [[String: String]]]] else {
            return nil
        }

        guard let appConfig = json[bundleID] else { return nil }

        var result: [ShortcutGroup] = []
        for (groupTitle, itemsList) in appConfig {
            var items: [ShortcutItem] = []
            for itemDict in itemsList {
                if let title = itemDict["title"], let keys = itemDict["keys"] {
                    items.append(ShortcutItem(title: title, keys: keys))
                }
            }
            if !items.isEmpty {
                result.append(ShortcutGroup(title: groupTitle, items: items))
            }
        }
        return result.isEmpty ? nil : result
    }
}

// MARK: - Accessibility Menu Scanner

class MenuScanner {
    static func decodeModifiers(_ mod: Int) -> String {
        var str = ""
        // Bits: 1 = Shift, 2 = Option, 4 = Control, 8 = No Command
        if (mod & 4) != 0 { str += "⌃" }
        if (mod & 2) != 0 { str += "⌥" }
        if (mod & 1) != 0 { str += "⇧" }
        if (mod & 8) == 0 { str += "⌘" }
        return str
    }

    static func decodeGlyph(_ char: String) -> String {
        switch char {
        case "\u{08}": return "⌫"
        case "\r": return "↩"
        case "\t": return "Tab"
        case "\u{1b}": return "Esc"
        default: return char
        }
    }

    static func scanMenu(element: AXUIElement, groupTitle: String, items: inout [ShortcutItem]) {
        var childrenVal: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let children = childrenVal as? [AXUIElement] else { return }

        for item in children {
            var titleVal: AnyObject?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleVal)

            var cmdCharVal: AnyObject?
            AXUIElementCopyAttributeValue(item, kAXMenuItemCmdCharAttribute as CFString, &cmdCharVal)

            var cmdModVal: AnyObject?
            AXUIElementCopyAttributeValue(item, kAXMenuItemCmdModifiersAttribute as CFString, &cmdModVal)

            if let title = titleVal as? String, !title.isEmpty,
               let cmd = cmdCharVal as? String, !cmd.isEmpty {
                let modInt = (cmdModVal as? Int) ?? 0
                let modStr = decodeModifiers(modInt)
                let keyStr = modStr + decodeGlyph(cmd)
                items.append(ShortcutItem(title: title, keys: keyStr))
            }

            // Recurse submenus
            scanMenu(element: item, groupTitle: groupTitle, items: &items)
        }
    }

    static func scan(app: NSRunningApplication) -> [ShortcutGroup] {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var menuBarVal: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarVal) == .success,
              let menuBar = menuBarVal else { return [] }

        var childrenVal: AnyObject?
        guard AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let children = childrenVal as? [AXUIElement] else { return [] }

        var groups: [ShortcutGroup] = []
        for child in children {
            var titleVal: AnyObject?
            AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleVal)
            guard let title = titleVal as? String, !title.isEmpty, title != "Apple" else { continue }

            var items: [ShortcutItem] = []
            scanMenu(element: child, groupTitle: title, items: &items)
            if !items.isEmpty {
                groups.append(ShortcutGroup(title: title, items: items))
            }
        }
        return groups
    }
}

// MARK: - Search State

class SearchState: ObservableObject {
    @Published var query: String = ""
}

// MARK: - Auto-Focusing Native Search Field

struct SearchBarView: NSViewRepresentable {
    @Binding var text: String
    var onEscape: () -> Void

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SearchBarView
        init(_ parent: SearchBarView) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            if let tf = obj.object as? NSTextField {
                parent.text = tf.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.placeholderString = "Search shortcuts... (Esc to close)"
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.font = NSFont.systemFont(ofSize: 13)
        tf.textColor = .white
        tf.delegate = context.coordinator

        DispatchQueue.main.async {
            tf.window?.makeFirstResponder(tf)
        }
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
}

// MARK: - SwiftUI HUD View

struct HUDView: View {
    let appName: String
    let appIcon: NSImage?
    let groups: [ShortcutGroup]
    let onDismiss: () -> Void

    @ObservedObject var searchState: SearchState

    var filteredGroups: [ShortcutGroup] {
        let q = searchState.query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            return groups
        }
        return groups.compactMap { group in
            let filteredItems = group.items.filter {
                $0.title.lowercased().contains(q) || $0.keys.lowercased().contains(q)
            }
            return filteredItems.isEmpty ? nil : ShortcutGroup(title: group.title, items: filteredItems)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag Header / Search Bar
            HStack(spacing: 12) {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                Text(appName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Search Field Container
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    SearchBarView(text: $searchState.query, onEscape: onDismiss)
                        .frame(height: 22)

                    if !searchState.query.isEmpty {
                        Button(action: { searchState.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .cornerRadius(8)
                .frame(width: 320)

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()
                .background(Color.white.opacity(0.15))

            // Resizable Columns Content
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(filteredGroups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.title.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.cyan)
                                    .padding(.bottom, 2)

                                ScrollView(.vertical, showsIndicators: true) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(group.items) { item in
                                            HStack(alignment: .center) {
                                                Text(item.title)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white.opacity(0.92))
                                                    .lineLimit(1)
                                                Spacer(minLength: 8)
                                                Text(item.keys)
                                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.white.opacity(0.16))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(5)
                                            }
                                        }
                                    }
                                    .padding(.trailing, 4)
                                }
                                .frame(maxHeight: .infinity)
                            }
                            .frame(width: 250)
                            .frame(maxHeight: .infinity)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                        }
                    }
                    .padding(18)
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 350)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.85)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
}

// MARK: - Native Visual Effect View for Blur

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

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

    init() {
        let panel = KeyHUDPanel(
            contentRect: NSRect(x: 100, y: 100, width: 900, height: 600),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
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
        panel.minSize = NSSize(width: 500, height: 350)

        super.init(window: panel)
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

    func applyScreenPercentageFrame() {
        guard let window = window else { return }
        let screen = targetScreen()
        let visible = screen.visibleFrame
        let settings = AppSettings.shared

        let targetWidth = visible.width * (settings.widthPercent / 100.0)
        let targetHeight = visible.height * (settings.heightPercent / 100.0)
        let originX = visible.origin.x + (visible.width - targetWidth) / 2.0
        let originY = visible.origin.y + (visible.height - targetHeight) / 2.0

        let targetFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
        window.setFrame(targetFrame, display: true, animate: false)
    }

    func toggle(targetApp: NSRunningApplication? = nil) {
        guard let window = window else { return }
        if window.isVisible {
            hide()
        } else {
            show(for: targetApp ?? NSWorkspace.shared.frontmostApplication)
        }
    }

    func show(for app: NSRunningApplication?) {
        guard let window = window, let app = app else { return }

        searchState.query = ""

        let bundleID = app.bundleIdentifier ?? ""
        let appName = app.localizedName ?? "Application"
        let icon = app.icon

        // Check Custom Override first (e.g. Ghostty)
        let groups: [ShortcutGroup]
        if let customGroups = CustomShortcutsManager.shared.groups(for: bundleID) {
            groups = customGroups
        } else {
            groups = MenuScanner.scan(app: app)
        }

        let hudView = HUDView(appName: appName, appIcon: icon, groups: groups, onDismiss: { [weak self] in
            self?.hide()
        }, searchState: searchState)

        window.contentView = NSHostingView(rootView: hudView)

        // Apply custom percent of active screen
        applyScreenPercentageFrame()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Monitor Esc key locally to dismiss
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
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

// MARK: - Settings Window & View

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
                Text("KeyHUD Settings")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 14) {
                // Width Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Horizontal Size (% of screen):")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(settings.widthPercent))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Slider(value: $settings.widthPercent, in: 25...100, step: 1)
                }

                // Height Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Vertical Size (% of screen):")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(settings.heightPercent))%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Slider(value: $settings.heightPercent, in: 25...100, step: 1)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)

            HStack {
                Button("Reset Defaults") {
                    settings.widthPercent = 75
                    settings.heightPercent = 65
                    HUDWindowController.shared.applyScreenPercentageFrame()
                }

                Spacer()

                Button("Done") {
                    HUDWindowController.shared.applyScreenPercentageFrame()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 380)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyHUD Settings"
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let view = SettingsView { [weak self] in
            self?.close()
        }
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func openSettings() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - HotKey & Command Listener

class HotKeyManager {
    static let shared = HotKeyManager()
    private var cmdPressStartTime: Date?
    private var timer: Timer?

    func start() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 44 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
            }
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isCmdPressed = event.modifierFlags.contains(.command)
        let onlyCmd = isCmdPressed && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.option) && !event.modifierFlags.contains(.control)

        if onlyCmd {
            if cmdPressStartTime == nil {
                cmdPressStartTime = Date()
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { _ in
                    DispatchQueue.main.async {
                        HUDWindowController.shared.show(for: NSWorkspace.shared.frontmostApplication)
                    }
                }
            }
        } else {
            cmdPressStartTime = nil
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.circle", accessibilityDescription: "KeyHUD")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle KeyHUD (⌘⇧/ or Hold ⌘)", action: #selector(toggleHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Open Shortcuts JSON...", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyHUD", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu

        HotKeyManager.shared.start()
    }

    @objc func toggleHUD() {
        HUDWindowController.shared.toggle()
    }

    @objc func openSettings() {
        SettingsWindowController.shared.openSettings()
    }

    @objc func openConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let url = URL(fileURLWithPath: "\(home)/.config/keyhud/custom_shortcuts.json")
        NSWorkspace.shared.open(url)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
