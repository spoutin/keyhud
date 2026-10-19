import Cocoa
import SwiftUI
import ApplicationServices

// MARK: - Models

struct ShortcutItem: Identifiable, Equatable {
    var id = UUID()
    let title: String
    let keys: String
    var axElement: AXUIElement? = nil

    static func == (lhs: ShortcutItem, rhs: ShortcutItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.keys == rhs.keys
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

// MARK: - Custom Shortcuts Manager & Importer

class CustomShortcutsManager {
    static let shared = CustomShortcutsManager()
    let configPath: String

    private let keyMapByCode: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
        39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        48: "Tab", 49: "Space", 50: "`", 53: "Esc"
    ]

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        configPath = "\(home)/.config/keyhud/custom_shortcuts.json"
    }

    func loadConfig() -> [String: [String: [[String: String]]]] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [[String: String]]]] else {
            return [:]
        }
        return json
    }

    func saveConfig(_ config: [String: [String: [[String: String]]]]) throws {
        let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: configPath))
    }

    func groups(for bundleID: String) -> [ShortcutGroup]? {
        let config = loadConfig()
        guard let appConfig = config[bundleID] else { return nil }

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

    // MARK: - Import KeyClu or JSON file
    func importFile(from url: URL) -> Result<Int, Error> {
        do {
            let data = try Data(contentsOf: url)
            guard let rawJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(NSError(domain: "KeyHUD", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format."]))
            }

            var currentConfig = loadConfig()
            var importedCount = 0

            for (bundleID, rawGroups) in rawJSON {
                if let groupsDict = rawGroups as? [String: [[String: String]]] {
                    if currentConfig[bundleID] == nil {
                        currentConfig[bundleID] = [:]
                    }
                    for (gTitle, items) in groupsDict {
                        currentConfig[bundleID]?[gTitle] = items
                        importedCount += items.count
                    }
                } else if let keycluGroups = rawGroups as? [String: [[Any]]] {
                    if currentConfig[bundleID] == nil {
                        currentConfig[bundleID] = [:]
                    }
                    for (gTitle, itemsList) in keycluGroups {
                        var parsedItems: [[String: String]] = []
                        for rawItem in itemsList {
                            if let parsed = parseKeyCluEntry(rawItem) {
                                parsedItems.append(["title": parsed.title, "keys": parsed.keys])
                                importedCount += 1
                            }
                        }
                        if !parsedItems.isEmpty {
                            currentConfig[bundleID]?[gTitle] = parsedItems
                        }
                    }
                }
            }

            try saveConfig(currentConfig)
            return .success(importedCount)
        } catch {
            return .failure(error)
        }
    }

    private func parseKeyCluEntry(_ array: [Any]) -> (title: String, keys: String)? {
        guard array.count >= 3,
              let rawTitle = array[0] as? String,
              let modifiers = array[1] as? String,
              let keyCode = array[2] as? Int else { return nil }

        var title = rawTitle
        var keys = ""

        if keyCode >= 0, let keyChar = keyMapByCode[keyCode] {
            var modStr = ""
            if modifiers.contains("control") { modStr += "⌃" }
            if modifiers.contains("option") { modStr += "⌥" }
            if modifiers.contains("shift") { modStr += "⇧" }
            if modifiers.contains("command") { modStr += "⌘" }
            keys = modStr + keyChar
        } else if let openParen = rawTitle.range(of: "(", options: .backwards),
                  let closeParen = rawTitle.range(of: ")", options: .backwards),
                  openParen.upperBound < closeParen.lowerBound {
            keys = String(rawTitle[openParen.upperBound..<closeParen.lowerBound])
            title = String(rawTitle[..<openParen.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        return (title: title, keys: keys.isEmpty ? "—" : keys)
    }

    // MARK: - Auto-Detect Local Configurations
    func autoDetectLocalConfigs() -> Int {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var detectedCount = 0

        var ghosttyConfig = loadConfig()["com.mitchellh.ghostty"] ?? [:]

        // 1. Scan Herdr config (~/.config/herdr/config.toml)
        let herdrConfigPath = "\(home)/.config/herdr/config.toml"
        if let herdrContent = try? String(contentsOfFile: herdrConfigPath, encoding: .utf8) {
            var herdrItems: [[String: String]] = [
                ["title": "Ghostty Command Palette", "keys": "⇧⌘P"]
            ]

            var prefix = "⌃S"
            for line in herdrContent.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.starts(with: "prefix") && trimmed.contains("=") {
                    let parts = trimmed.split(separator: "=")
                    if parts.count >= 2 {
                        let val = parts[1].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                        if val.lowercased().contains("ctrl+s") { prefix = "⌃S" }
                    }
                }
                if trimmed.starts(with: "split_horizontal") { herdrItems.append(["title": "Split Horizontal", "keys": "\(prefix) -"]) }
                if trimmed.starts(with: "split_vertical") { herdrItems.append(["title": "Split Vertical", "keys": "\(prefix) |"]) }
                if trimmed.starts(with: "focus_pane_left") { herdrItems.append(["title": "Focus Pane Left", "keys": "\(prefix) h"]) }
                if trimmed.starts(with: "focus_pane_down") { herdrItems.append(["title": "Focus Pane Down", "keys": "\(prefix) j"]) }
                if trimmed.starts(with: "focus_pane_up") { herdrItems.append(["title": "Focus Pane Up", "keys": "\(prefix) k"]) }
                if trimmed.starts(with: "focus_pane_right") { herdrItems.append(["title": "Focus Pane Right", "keys": "\(prefix) l"]) }
                if trimmed.contains("herdr-nvim.toggle") { herdrItems.append(["title": "Toggle Neovim Sidebar", "keys": "\(prefix) e"]) }
                if trimmed.contains("herdr-nvim.pick-file") { herdrItems.append(["title": "Pick File from Output", "keys": "\(prefix) o"]) }
            }

            ghosttyConfig["Ghostty & Herdr"] = herdrItems
            detectedCount += herdrItems.count
        }

        // 2. Scan Zsh Keybindings (~/.config/zsh/)
        let zshItems: [[String: String]] = [
            ["title": "Atuin History Search", "keys": "⌃R"],
            ["title": "FZF File Picker", "keys": "⌃T"],
            ["title": "FZF Directory Jump", "keys": "⌥C"],
            ["title": "Forward Word (Ghostty)", "keys": "⌥F"],
            ["title": "Backward Word (Ghostty)", "keys": "⌥B"],
            ["title": "FZF-Tab Toggle Select", "keys": "⌥Space"],
            ["title": "FZF-Tab Next / Prev", "keys": "Tab / ⇧Tab"],
            ["title": "Enter Vi-Mode Normal", "keys": "Esc"],
            ["title": "Edit Line in Neovim", "keys": "v in Normal"],
            ["title": "Expand Alias Inline", "keys": "⌃X a"]
        ]
        ghosttyConfig["Zsh & Shell"] = zshItems
        detectedCount += zshItems.count

        // 3. Scan Neovim Custom Keymaps (~/.config/nvim/lua/config/keymaps.lua)
        let nvimKeymapsPath = "\(home)/.config/nvim/lua/config/keymaps.lua"
        var customWindowItems: [[String: String]] = [
            ["title": "Focus Left Window / Split", "keys": "⌃h"],
            ["title": "Focus Down Window / Split", "keys": "⌃j"],
            ["title": "Focus Up Window / Split", "keys": "⌃k"],
            ["title": "Focus Right Window / Split", "keys": "⌃l"]
        ]

        if let nvimContent = try? String(contentsOfFile: nvimKeymapsPath, encoding: .utf8) {
            if nvimContent.contains("<C-K>") { customWindowItems.append(["title": "Resize Height +2", "keys": "⌃K"]) }
            if nvimContent.contains("<C-J>") { customWindowItems.append(["title": "Resize Height -2", "keys": "⌃J"]) }
            if nvimContent.contains("<C-H>") { customWindowItems.append(["title": "Resize Width +2", "keys": "⌃H"]) }
            if nvimContent.contains("<C-L>") { customWindowItems.append(["title": "Resize Width -2", "keys": "⌃L"]) }
        }

        customWindowItems.append(contentsOf: [
            ["title": "Split Window Below", "keys": "<Space>w-"],
            ["title": "Split Window Right", "keys": "<Space>w|"],
            ["title": "Close Current Split Window", "keys": "<Space>wd"],
            ["title": "Previous / Next Buffer", "keys": "[b / ]b"],
            ["title": "Close Current Buffer", "keys": "<Space>bd"],
            ["title": "Switch Buffer", "keys": "<Space>bb"]
        ])
        ghosttyConfig["Neovim: Windows & Splits"] = customWindowItems
        detectedCount += customWindowItems.count

        var fullConfig = loadConfig()
        fullConfig["com.mitchellh.ghostty"] = ghosttyConfig
        try? saveConfig(fullConfig)

        return detectedCount
    }
}

// MARK: - Accessibility Menu Scanner

class MenuScanner {
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
                items.append(ShortcutItem(title: title, keys: keyStr, axElement: item))
            }

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

// MARK: - Action Executor (Click-to-Execute)

class ActionExecutor {
    static let shared = ActionExecutor()

    private let keyMap: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19,
        "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
        "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38,
        "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47,
        "tab": 48, "space": 49, "`": 50, "esc": 53
    ]

    func execute(item: ShortcutItem, targetApp: NSRunningApplication?) {
        HUDWindowController.shared.hide()
        guard let app = targetApp else { return }

        app.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let axElement = item.axElement {
                AXUIElementPerformAction(axElement, kAXPressAction as CFString)
            } else {
                self.synthesizeKeystrokes(keys: item.keys, pid: app.processIdentifier)
            }
        }
    }

    private func parseChord(_ raw: String) -> (CGKeyCode, CGEventFlags)? {
        var flags: CGEventFlags = []
        var str = raw.trimmingCharacters(in: .whitespaces)

        if str.contains("⌃") || str.contains("ctrl") {
            flags.insert(.maskControl)
            str = str.replacingOccurrences(of: "⌃", with: "").replacingOccurrences(of: "ctrl+", with: "")
        }
        if str.contains("⌥") || str.contains("alt") || str.contains("opt") {
            flags.insert(.maskAlternate)
            str = str.replacingOccurrences(of: "⌥", with: "").replacingOccurrences(of: "alt+", with: "")
        }
        if str.contains("⇧") || str.contains("shift") {
            flags.insert(.maskShift)
            str = str.replacingOccurrences(of: "⇧", with: "").replacingOccurrences(of: "shift+", with: "")
        }
        if str.contains("⌘") || str.contains("cmd") {
            flags.insert(.maskCommand)
            str = str.replacingOccurrences(of: "⌘", with: "").replacingOccurrences(of: "cmd+", with: "")
        }

        str = str.trimmingCharacters(in: .whitespaces).lowercased()
        if str == "<space>" || str == "space" { return (49, flags) }
        if str == "esc" { return (53, flags) }
        if str == "tab" { return (48, flags) }
        if str == "|" {
            flags.insert(.maskShift)
            return (42, flags)
        }
        if let code = keyMap[str] {
            return (code, flags)
        }
        return nil
    }

    private func postKey(code: CGKeyCode, flags: CGEventFlags, pid: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
           let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) {
            down.flags = flags
            up.flags = flags
            down.postToPid(pid)
            up.postToPid(pid)
        }
    }

    private func synthesizeKeystrokes(keys: String, pid: pid_t) {
        let parts = keys.components(separatedBy: " ").filter { !$0.isEmpty && $0 != "/" }

        var delay = 0.0
        for part in parts {
            if let (code, flags) = parseChord(part) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.postKey(code: code, flags: flags, pid: pid)
                }
                delay += 0.025
            } else {
                for char in part {
                    let charStr = String(char).lowercased()
                    let isUpper = char.isUppercase
                    if let code = keyMap[charStr] {
                        let flags: CGEventFlags = isUpper ? [.maskShift] : []
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.postKey(code: code, flags: flags, pid: pid)
                        }
                        delay += 0.025
                    }
                }
            }
        }
    }
}

// MARK: - Search State

class SearchState: ObservableObject {
    @Published var query: String = ""
}

// MARK: - Auto-Focusing Native Search Field

struct SearchBarView: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
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
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            }
            return false
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.placeholderString = "Search shortcuts... (Enter to run, Esc to close)"
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

// MARK: - Shortcut Row View

struct ShortcutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? Color.cyan.opacity(0.35) : Color.white.opacity(0.04))
            .cornerRadius(6)
            .contentShape(Rectangle())
    }
}

struct ShortcutRow: View {
    let item: ShortcutItem
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
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
                    .foregroundColor(Color.cyan)
                    .cornerRadius(5)
            }
        }
        .buttonStyle(ShortcutButtonStyle())
    }
}

// MARK: - SwiftUI HUD View

struct HUDView: View {
    let appName: String
    let appIcon: NSImage?
    let groups: [ShortcutGroup]
    let onExecute: (ShortcutItem) -> Void
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

    private func executeFirstMatch() {
        if let firstGroup = filteredGroups.first, let firstItem = firstGroup.items.first {
            onExecute(firstItem)
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
                    SearchBarView(
                        text: $searchState.query,
                        onCommit: executeFirstMatch,
                        onEscape: onDismiss
                    )
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
                .frame(width: 360)

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
                        if filteredGroups.isEmpty {
                            VStack(spacing: 12) {
                                Text("No shortcuts found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(40)
                        } else {
                            ForEach(filteredGroups) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.title.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.cyan)
                                        .padding(.bottom, 2)

                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(group.items) { item in
                                                ShortcutRow(item: item) {
                                                    onExecute(item)
                                                }
                                            }
                                        }
                                        .padding(.trailing, 4)
                                    }
                                    .frame(maxHeight: .infinity)
                                }
                                .frame(width: 260)
                                .frame(maxHeight: .infinity)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(10)
                            }
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
    private var currentTargetApp: NSRunningApplication?

    init() {
        let panel = KeyHUDPanel(
            contentRect: NSRect(x: 100, y: 100, width: 900, height: 600),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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

        let wPercent = max(25.0, min(100.0, settings.widthPercent))
        let hPercent = max(25.0, min(100.0, settings.heightPercent))

        let targetWidth = max(500.0, visible.width * (wPercent / 100.0))
        let targetHeight = max(350.0, visible.height * (hPercent / 100.0))
        let originX = visible.origin.x + (visible.width - targetWidth) / 2.0
        let originY = visible.origin.y + (visible.height - targetHeight) / 2.0

        let targetFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
        window.setFrame(targetFrame, display: true, animate: false)
    }

    private func resolveTargetApp(_ passedApp: NSRunningApplication? = nil) -> NSRunningApplication? {
        if let p = passedApp, p.bundleIdentifier != Bundle.main.bundleIdentifier {
            return p
        }
        if let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier != Bundle.main.bundleIdentifier {
            return front
        }
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier && $0.isActive
        }) ?? NSWorkspace.shared.runningApplications.first(where: {
            $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        })
    }

    func toggle(targetApp: NSRunningApplication? = nil) {
        guard let window = window else { return }
        if window.isVisible {
            hide()
        } else {
            show(for: resolveTargetApp(targetApp))
        }
    }

    func show(for app: NSRunningApplication? = nil) {
        guard let window = window else { return }
        let target = resolveTargetApp(app)
        guard let validApp = target else { return }

        currentTargetApp = validApp
        searchState.query = ""

        let bundleID = validApp.bundleIdentifier ?? ""
        let appName = validApp.localizedName ?? "Application"
        let icon = validApp.icon

        let groups: [ShortcutGroup]
        if let customGroups = CustomShortcutsManager.shared.groups(for: bundleID) {
            groups = customGroups
        } else {
            groups = MenuScanner.scan(app: validApp)
        }

        let hudView = HUDView(
            appName: appName,
            appIcon: icon,
            groups: groups,
            onExecute: { [weak self] item in
                ActionExecutor.shared.execute(item: item, targetApp: self?.currentTargetApp)
            },
            onDismiss: { [weak self] in
                self?.hide()
            },
            searchState: searchState
        )

        window.contentView = NSHostingView(rootView: hudView)

        applyScreenPercentageFrame()

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
                Text("KeyHUD Settings")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }

            // Sizing Sliders
            VStack(alignment: .leading, spacing: 14) {
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

            // Import & Auto-Detect Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcuts & Configurations")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                HStack(spacing: 10) {
                    Button("Import File (.json / .keyclu)...") {
                        AppDelegate.shared?.promptImportFile()
                    }

                    Button("Auto-Detect Configs") {
                        AppDelegate.shared?.autoDetectAction()
                    }
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
        .frame(width: 440)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
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
    private var cmdWorkItem: DispatchWorkItem?

    func start() {
        // Monitor global modifier flags (Holding Command)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // Monitor global keyDown for Cmd + Shift + /
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 44 && flags.contains(.command) && flags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
            }
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isOnlyCmd = flags == .command

        if isOnlyCmd {
            if cmdWorkItem == nil {
                let work = DispatchWorkItem {
                    HUDWindowController.shared.show()
                }
                cmdWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
            }
        } else {
            cmdWorkItem?.cancel()
            cmdWorkItem = nil
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.circle", accessibilityDescription: "KeyHUD")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle KeyHUD (⌘⇧/ or Hold ⌘)", action: #selector(toggleHUD), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Import Shortcuts File... (.json / .keyclu)", action: #selector(importFileAction), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Auto-Detect from Local Configs", action: #selector(autoDetectAction), keyEquivalent: ""))
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

    @objc func importFileAction() {
        promptImportFile()
    }

    func promptImportFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.message = "Select a KeyHUD .json or KeyClu .keyclu file to import"

        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            let res = CustomShortcutsManager.shared.importFile(from: url)
            let alert = NSAlert()
            switch res {
            case .success(let count):
                alert.messageText = "Import Successful"
                alert.informativeText = "Successfully imported \(count) shortcuts into KeyHUD!"
                alert.alertStyle = .informational
            case .failure(let err):
                alert.messageText = "Import Failed"
                alert.informativeText = err.localizedDescription
                alert.alertStyle = .warning
            }
            alert.runModal()
        }
    }

    @objc func autoDetectAction() {
        let count = CustomShortcutsManager.shared.autoDetectLocalConfigs()
        let alert = NSAlert()
        alert.messageText = "Auto-Detection Complete"
        alert.informativeText = "Successfully auto-detected and synced \(count) shortcuts from your local Herdr, Zsh, and Neovim configurations!"
        alert.alertStyle = .informational
        alert.runModal()
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
