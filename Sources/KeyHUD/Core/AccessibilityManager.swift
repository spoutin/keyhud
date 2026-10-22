import Foundation
import AppKit

// MARK: - Accessibility Menu Scanner

class MenuScanner {
    private static var menuCache: [String: [ShortcutGroup]] = [:]
    private static let cacheLock = NSLock()
    private static var isScanning = Set<String>()

    static func cached(for bundleID: String) -> [ShortcutGroup]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return menuCache[bundleID]
    }

    static func invalidate(bundleID: String) {
        cacheLock.lock()
        menuCache.removeValue(forKey: bundleID)
        cacheLock.unlock()
    }

    static func prewarm(app: NSRunningApplication) {
        let bID = app.bundleIdentifier ?? "\(app.processIdentifier)"
        if bID == Bundle.main.bundleIdentifier || bID == "com.mitchellh.ghostty" { return }
        cacheLock.lock()
        if menuCache[bID] != nil || isScanning.contains(bID) {
            cacheLock.unlock()
            return
        }
        isScanning.insert(bID)
        cacheLock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            _ = scan(app: app)
            cacheLock.lock()
            isScanning.remove(bID)
            cacheLock.unlock()
        }
    }

    static func decodeModifiers(_ mod: Int) -> String {
        var str = ""
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

    static func scanMenu(element: AXUIElement, groupTitle: String, parentPath: String = "", items: inout [ShortcutItem]) {
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

            var isSubmenu = false
            var subChildrenVal: AnyObject?
            if AXUIElementCopyAttributeValue(item, kAXChildrenAttribute as CFString, &subChildrenVal) == .success,
               let subKids = subChildrenVal as? [AXUIElement], !subKids.isEmpty {
                isSubmenu = true
            }

            if let title = titleVal as? String, !title.isEmpty {
                let fullTitle = parentPath.isEmpty ? title : "\(parentPath) > \(title)"

                if let cmd = cmdCharVal as? String, !cmd.isEmpty {
                    let modInt = (cmdModVal as? Int) ?? 0
                    let modStr = decodeModifiers(modInt)
                    let keyStr = modStr + decodeGlyph(cmd)
                    items.append(ShortcutItem(title: fullTitle, keys: keyStr, axElement: item))
                } else if !isSubmenu {
                    // Clickable action without a keyboard shortcut
                    items.append(ShortcutItem(title: fullTitle, keys: "", axElement: item))
                }
            }

            let nextParent = (titleVal as? String) ?? ""
            let nextPath = parentPath.isEmpty ? nextParent : "\(parentPath) > \(nextParent)"
            scanMenu(element: item, groupTitle: groupTitle, parentPath: nextPath, items: &items)
        }
    }

    static func scan(app: NSRunningApplication) -> [ShortcutGroup] {
        let bID = app.bundleIdentifier ?? "\(app.processIdentifier)"
        cacheLock.lock()
        if let cached = menuCache[bID], !cached.isEmpty {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var menuBarVal: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarVal) == .success,
              let menuBar = menuBarVal else { return [] }

        DispatchQueue.main.async {
            if !PermissionChecker.shared.isAccessibilityGranted {
                PermissionChecker.shared.isAccessibilityGranted = true
            }
        }

        var childrenVal: AnyObject?
        guard AXUIElementCopyAttributeValue(menuBar as! AXUIElement, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let children = childrenVal as? [AXUIElement] else { return [] }

        var groups: [ShortcutGroup] = []
        for child in children {
            var titleVal: AnyObject?
            AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleVal)
            guard let title = titleVal as? String, !title.isEmpty, title != "Apple" else { continue }

            var items: [ShortcutItem] = []
            scanMenu(element: child, groupTitle: title, parentPath: "", items: &items)
            if !items.isEmpty {
                groups.append(ShortcutGroup(title: title, items: items))
            }
        }
        cacheLock.lock()
        menuCache[bID] = groups
        cacheLock.unlock()
        return groups
    }
}

// MARK: - Permissions Checker

class PermissionChecker: ObservableObject {
    static let shared = PermissionChecker()
    @Published var isAccessibilityGranted: Bool = AXIsProcessTrusted()
    private var timer: Timer?

    init() {
        refresh()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func refresh() {
        if AXIsProcessTrusted() {
            if !isAccessibilityGranted {
                DispatchQueue.main.async {
                    self.isAccessibilityGranted = true
                }
            }
            return
        }

        // Run live IPC probe in background so main thread never hitches
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var current = AXIsProcessTrusted()
            if !current {
                let probeApp = NSWorkspace.shared.runningApplications.first(where: {
                    $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
                })
                if let probe = probeApp {
                    let axApp = AXUIElementCreateApplication(probe.processIdentifier)
                    var mb: AnyObject?
                    if AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &mb) == .success {
                        current = true
                    }
                }
            }
            if self.isAccessibilityGranted != current {
                DispatchQueue.main.async {
                    self.isAccessibilityGranted = current
                }
            }
        }
    }
}
