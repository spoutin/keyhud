import Cocoa
import SwiftUI
import ApplicationServices
import ServiceManagement

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

enum AccentTheme: String, CaseIterable, Identifiable {
    case cyan = "Cyan"
    case mauve = "Mauve"
    case blue = "Sapphire Blue"
    case green = "Neon Green"
    case amber = "Amber"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .cyan: return Color(red: 0.0, green: 0.85, blue: 1.0)
        case .mauve: return Color(red: 0.78, green: 0.63, blue: 0.98)
        case .blue: return Color(red: 0.54, green: 0.77, blue: 0.98)
        case .green: return Color(red: 0.40, green: 0.95, blue: 0.60)
        case .amber: return Color(red: 1.0, green: 0.75, blue: 0.40)
        }
    }
}

enum TriggerType: Int, CaseIterable, Identifiable {
    case doubleTapAndHold = 0
    case tripleTap = 1
    case singleHold = 2
    case doubleTap = 3
    case hotkeyOnly = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .doubleTapAndHold: return "Double-Tap ⌘ and Hold (Recommended)"
        case .tripleTap: return "Triple-Tap ⌘"
        case .singleHold: return "Hold ⌘"
        case .doubleTap: return "Double-Tap ⌘"
        case .hotkeyOnly: return "Shortcut Only (⌘⇧/)"
        }
    }

    var subtitle: String {
        switch self {
        case .doubleTapAndHold: return "Tap Command twice quickly and hold down on the second tap"
        case .tripleTap: return "Tap Command three times in rapid succession"
        case .singleHold: return "Press and hold Command key down"
        case .doubleTap: return "Tap Command key twice in rapid succession"
        case .hotkeyOnly: return "Exclusively use ⌘⇧/ hotkey (disables modifier tapping)"
        }
    }

    var shortBadge: String {
        switch self {
        case .doubleTapAndHold: return "Double-Tap ⌘ & Hold"
        case .tripleTap: return "Triple-Tap ⌘"
        case .singleHold: return "Hold ⌘"
        case .doubleTap: return "Double-Tap ⌘"
        case .hotkeyOnly: return "⌘⇧/ Only"
        }
    }
}

enum ColorSchemeMode: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var appearance: NSAppearance? {
        switch self {
        case .automatic: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Settings & Preferences

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var appearanceMode: String {
        didSet {
            UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode")
            updateWindowsAppearance()
        }
    }
    @Published var widthPercent: Double {
        didSet {
            UserDefaults.standard.set(widthPercent, forKey: "widthPercent")
        }
    }
    @Published var heightPercent: Double {
        didSet {
            UserDefaults.standard.set(heightPercent, forKey: "heightPercent")
        }
    }
    @Published var triggerType: Int {
        didSet {
            UserDefaults.standard.set(triggerType, forKey: "triggerType")
            AppDelegate.shared?.updateToggleMenuItemTitle()
        }
    }
    @Published var holdDuration: Double {
        didSet {
            UserDefaults.standard.set(holdDuration, forKey: "holdDuration")
        }
    }
    @Published var accentTheme: String {
        didSet {
            UserDefaults.standard.set(accentTheme, forKey: "accentTheme")
        }
    }
    @Published var isPinned: Bool {
        didSet {
            UserDefaults.standard.set(isPinned, forKey: "isPinned")
        }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            _ = LaunchAtLoginManager.shared.setEnabled(launchAtLogin)
        }
    }
    @Published var ghosttyHiddenCategories: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(ghosttyHiddenCategories), forKey: "ghosttyHiddenCategories")
        }
    }
    @Published var selectedSettingsTab: String = SettingsTab.general.rawValue

    func isGhosttyCategoryShownOnMain(_ name: String) -> Bool {
        return !ghosttyHiddenCategories.contains(name)
    }

    func toggleGhosttyCategoryOnMain(_ name: String) {
        if ghosttyHiddenCategories.contains(name) {
            ghosttyHiddenCategories.remove(name)
        } else {
            ghosttyHiddenCategories.insert(name)
        }
    }

    var currentAccentColor: Color {
        AccentTheme(rawValue: accentTheme)?.color ?? AccentTheme.cyan.color
    }

    var currentColorMode: ColorSchemeMode {
        ColorSchemeMode(rawValue: appearanceMode) ?? .dark
    }

    func updateWindowsAppearance() {
        let appMode = currentColorMode.appearance
        HUDWindowController.shared.window?.appearance = appMode
        SettingsWindowController.shared.window?.appearance = appMode
        KeybindingEditorWindowController.shared.window?.appearance = appMode
    }

    init() {
        let savedApp = UserDefaults.standard.string(forKey: "appearanceMode")
        self.appearanceMode = (savedApp != nil && ColorSchemeMode(rawValue: savedApp!) != nil) ? savedApp! : ColorSchemeMode.dark.rawValue

        let savedW = UserDefaults.standard.double(forKey: "widthPercent")
        self.widthPercent = (savedW >= 20 && savedW <= 100) ? savedW : 75.0

        let savedH = UserDefaults.standard.double(forKey: "heightPercent")
        self.heightPercent = (savedH >= 20 && savedH <= 100) ? savedH : 65.0

        let savedTrigger = UserDefaults.standard.integer(forKey: "triggerType")
        self.triggerType = (savedTrigger >= 0 && savedTrigger <= 4) ? savedTrigger : 0

        let savedHold = UserDefaults.standard.double(forKey: "holdDuration")
        self.holdDuration = (savedHold >= 0.15 && savedHold <= 1.0) ? savedHold : 0.35

        let savedTheme = UserDefaults.standard.string(forKey: "accentTheme")
        self.accentTheme = (savedTheme != nil && AccentTheme(rawValue: savedTheme!) != nil) ? savedTheme! : AccentTheme.cyan.rawValue

        self.isPinned = UserDefaults.standard.bool(forKey: "isPinned")
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled

        let savedHidden = UserDefaults.standard.stringArray(forKey: "ghosttyHiddenCategories") ?? []
        self.ghosttyHiddenCategories = Set(savedHidden)
    }
}

// MARK: - Launch at Login Manager

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    let bundleID = "com.ablack.KeyHUD"
    let appPath = "/Applications/KeyHUD.app"

    var launchAgentURL: URL {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return libraryDir.appendingPathComponent("LaunchAgents/\(bundleID).plist")
    }

    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled { return true }
        }
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func setEnabled(_ enable: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                    return true
                } else {
                    try SMAppService.mainApp.unregister()
                    try? FileManager.default.removeItem(at: launchAgentURL)
                    return true
                }
            } catch {
                // Fall back to user LaunchAgent plist
            }
        }

        if enable {
            return createLaunchAgentPlist()
        } else {
            try? FileManager.default.removeItem(at: launchAgentURL)
            return true
        }
    }

    private func createLaunchAgentPlist() -> Bool {
        let executablePath = "\(appPath)/Contents/MacOS/KeyHUD"
        let plistDict: [String: Any] = [
            "Label": bundleID,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua"
        ]
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
            let folder = launchAgentURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: launchAgentURL)
            return true
        } catch {
            return false
        }
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

    func allAppBundleIDs() -> [String] {
        let config = loadConfig()
        return Array(config.keys).sorted()
    }

    func saveConfig(_ config: [String: [String: [[String: String]]]]) throws {
        let dir = URL(fileURLWithPath: configPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
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

    func autoDetectLocalConfigs() -> Int {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var detectedCount = 0
        var ghosttyConfig = loadConfig()["com.mitchellh.ghostty"] ?? [:]

        // 1. Scan Herdr config
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

        // 2. Scan Zsh Keybindings
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

        // 3. Scan Neovim Custom Keymaps
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

        // 4. Auto-detect from all running regular Mac apps (Chrome, Safari, Slack, Obsidian, Finder, etc.)
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            if let bid = app.bundleIdentifier, bid != Bundle.main.bundleIdentifier, bid != "com.mitchellh.ghostty" {
                if fullConfig[bid] == nil {
                    let scanned = MenuScanner.scan(app: app)
                    if !scanned.isEmpty {
                        var appDict: [String: [[String: String]]] = [:]
                        for group in scanned {
                            appDict[group.title] = group.items.map { ["title": $0.title, "keys": $0.keys] }
                            detectedCount += group.items.count
                        }
                        fullConfig[bid] = appDict
                    }
                }
            }
        }

        try? saveConfig(fullConfig)

        return detectedCount
    }
}

// MARK: - AeroSpace Config Parser

struct AeroSpaceConfigParser {
    static func defaultPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.config/aerospace/aerospace.toml"
    }

    static func parse(atPath path: String = defaultPath()) -> [ShortcutGroup] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return []
        }

        var focusItems: [ShortcutItem] = []
        var moveItems: [ShortcutItem] = []
        var layoutItems: [ShortcutItem] = []
        var workspaceItems: [ShortcutItem] = []
        var moveNodeItems: [ShortcutItem] = []
        var otherItems: [ShortcutItem] = []

        var inBindingMode = false
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.starts(with: "#") { continue }

            if trimmed.starts(with: "[") && trimmed.contains("binding") {
                inBindingMode = true
                continue
            } else if trimmed.starts(with: "[") && !trimmed.contains("binding") {
                inBindingMode = false
                continue
            }

            if inBindingMode && trimmed.contains("=") {
                let parts = trimmed.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    let rawKey = parts[0]
                    let rawCmd = parts[1].replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: "")

                    let formattedKey = formatAeroSpaceKey(rawKey)
                    let (title, category) = categorizeCommand(rawCmd)

                    let item = ShortcutItem(title: title, keys: formattedKey)
                    switch category {
                    case .focus: focusItems.append(item)
                    case .move: moveItems.append(item)
                    case .layout: layoutItems.append(item)
                    case .workspace: workspaceItems.append(item)
                    case .moveNode: moveNodeItems.append(item)
                    case .other: otherItems.append(item)
                    }
                }
            }
        }

        var groups: [ShortcutGroup] = []
        if !focusItems.isEmpty { groups.append(ShortcutGroup(title: "Window Focus & Navigation", items: focusItems)) }
        if !moveItems.isEmpty { groups.append(ShortcutGroup(title: "Window Movement", items: moveItems)) }
        if !layoutItems.isEmpty { groups.append(ShortcutGroup(title: "Layout & Resizing", items: layoutItems)) }
        if !workspaceItems.isEmpty { groups.append(ShortcutGroup(title: "Workspaces", items: workspaceItems)) }
        if !moveNodeItems.isEmpty { groups.append(ShortcutGroup(title: "Move Window to Workspace", items: moveNodeItems)) }
        if !otherItems.isEmpty { groups.append(ShortcutGroup(title: "Service & Misc", items: otherItems)) }

        return groups
    }

    private enum AeroCategory {
        case focus, move, layout, workspace, moveNode, other
    }

    private static func formatAeroSpaceKey(_ key: String) -> String {
        var mods = ""
        let parts = key.split(separator: "-").map { String($0) }
        for (idx, p) in parts.enumerated() {
            let lower = p.lowercased()
            if idx < parts.count - 1 {
                if lower == "alt" || lower == "opt" || lower == "option" { mods += "⌥" }
                else if lower == "cmd" || lower == "command" { mods += "⌘" }
                else if lower == "ctrl" || lower == "control" { mods += "⌃" }
                else if lower == "shift" { mods += "⇧" }
            } else {
                var finalKey = p
                if finalKey.count == 1 {
                    finalKey = finalKey.uppercased()
                } else if finalKey.lowercased() == "slash" {
                    finalKey = "/"
                } else if finalKey.lowercased() == "comma" {
                    finalKey = ","
                } else if finalKey.lowercased() == "period" {
                    finalKey = "."
                } else if finalKey.lowercased() == "minus" {
                    finalKey = "-"
                } else if finalKey.lowercased() == "equal" {
                    finalKey = "="
                } else if finalKey.lowercased() == "semicolon" {
                    finalKey = ";"
                } else if finalKey.lowercased() == "enter" {
                    finalKey = "↩"
                } else if finalKey.lowercased() == "space" {
                    finalKey = "Space"
                } else if finalKey.lowercased() == "esc" {
                    finalKey = "Esc"
                }
                return mods + finalKey
            }
        }
        return key
    }

    private static func categorizeCommand(_ cmd: String) -> (String, AeroCategory) {
        let clean = cmd.trimmingCharacters(in: CharacterSet(charactersIn: "[]'\" \t"))
        let lower = clean.lowercased()

        if lower.starts(with: "focus") {
            let dir = clean.replacingOccurrences(of: "focus", with: "").trimmingCharacters(in: .whitespaces)
            return ("Focus \(dir.capitalized)", .focus)
        } else if lower.starts(with: "move-node-to-workspace") {
            let ws = clean.replacingOccurrences(of: "move-node-to-workspace", with: "").trimmingCharacters(in: .whitespaces)
            return ("Move Node to Workspace \(ws)", .moveNode)
        } else if lower.starts(with: "workspace") {
            let ws = clean.replacingOccurrences(of: "workspace", with: "").trimmingCharacters(in: .whitespaces)
            if ws.lowercased().contains("back-and-forth") {
                return ("Workspace Back and Forth", .workspace)
            }
            return ("Switch to Workspace \(ws)", .workspace)
        } else if lower.starts(with: "move") {
            let dir = clean.replacingOccurrences(of: "move", with: "").trimmingCharacters(in: .whitespaces)
            return ("Move Window \(dir.capitalized)", .move)
        } else if lower.starts(with: "layout") || lower.starts(with: "resize") {
            return (clean.capitalized, .layout)
        } else if lower.contains("reload-config") {
            return ("Reload AeroSpace Config", .other)
        } else if lower.contains("mode") {
            return (clean, .other)
        }
        return (clean, .other)
    }
}

// MARK: - macOS Global Shortcuts Provider

struct MacOSGlobalShortcuts {
    static func getGroups() -> [ShortcutGroup] {
        return [
            ShortcutGroup(title: "Window & App Management", items: [
                ShortcutItem(title: "Switch Application", keys: "⌘⇥"),
                ShortcutItem(title: "Switch Windows in Current App", keys: "⌘`"),
                ShortcutItem(title: "Hide Current Application", keys: "⌘H"),
                ShortcutItem(title: "Hide Other Applications", keys: "⌥⌘H"),
                ShortcutItem(title: "Minimize Window", keys: "⌘M"),
                ShortcutItem(title: "Close Window", keys: "⌘W"),
                ShortcutItem(title: "Quit Application", keys: "⌘Q")
            ]),
            ShortcutGroup(title: "Screenshots & Screen Recording", items: [
                ShortcutItem(title: "Capture Entire Screen", keys: "⇧⌘3"),
                ShortcutItem(title: "Capture Selected Area / Window", keys: "⇧⌘4"),
                ShortcutItem(title: "Screenshot & Recording Options", keys: "⇧⌘5"),
                ShortcutItem(title: "Copy Selection to Clipboard", keys: "⌃⇧⌘4")
            ]),
            ShortcutGroup(title: "Mission Control & Spaces", items: [
                ShortcutItem(title: "Spotlight Search", keys: "⌘Space"),
                ShortcutItem(title: "Mission Control Overview", keys: "⌃↑"),
                ShortcutItem(title: "Application Windows (Exposé)", keys: "⌃↓"),
                ShortcutItem(title: "Move Space Left", keys: "⌃←"),
                ShortcutItem(title: "Move Space Right", keys: "⌃→"),
                ShortcutItem(title: "Show Desktop", keys: "F11")
            ]),
            ShortcutGroup(title: "System & Accessibility", items: [
                ShortcutItem(title: "Force Quit Applications", keys: "⌥⌘⎋"),
                ShortcutItem(title: "Lock Screen", keys: "⌃⌘Q"),
                ShortcutItem(title: "Toggle Dock Auto-Hide", keys: "⌥⌘D"),
                ShortcutItem(title: "Emoji & Character Viewer", keys: "⌃⌘Space")
            ])
        ]
    }
}

// MARK: - Keybinding Editor State

class EditorState: ObservableObject {
    static let shared = EditorState()
    @Published var config: [String: [String: [[String: String]]]] = [:]
    @Published var selectedBundleID: String = "" {
        didSet {
            autoDetectIfEmpty(for: selectedBundleID)
        }
    }
    @Published var isDirty: Bool = false
    @Published var newCategoryName: String = ""
    @Published var isAddingCategory: Bool = false
    @Published var isAddingApp: Bool = false
    @Published var newAppBundleID: String = ""

    init() {
        reload()
    }

    func reload(selecting targetBundleID: String? = nil) {
        let loaded = CustomShortcutsManager.shared.loadConfig()
        self.config = loaded
        self.isDirty = false
        if let target = targetBundleID, !target.isEmpty {
            if self.config[target] == nil {
                self.config[target] = [:]
            }
            self.selectedBundleID = target
        } else if !self.selectedBundleID.isEmpty && (self.config[self.selectedBundleID] != nil || availableApps.contains(self.selectedBundleID)) {
            // retain selection
        } else {
            self.selectedBundleID = loaded.keys.sorted().first ?? "com.mitchellh.ghostty"
        }
        autoDetectIfEmpty(for: self.selectedBundleID)
    }

    func autoDetectIfEmpty(for bundleID: String) {
        guard !bundleID.isEmpty else { return }
        if config[bundleID] == nil || config[bundleID]?.isEmpty == true {
            autoDetectFromRunningApp(bundleID: bundleID)
        }
    }

    func autoDetectFromRunningApp(bundleID: String) {
        guard !bundleID.isEmpty else { return }
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            let scanned = MenuScanner.scan(app: runningApp)
            if !scanned.isEmpty {
                var appDict: [String: [[String: String]]] = [:]
                for group in scanned {
                    appDict[group.title] = group.items.map { ["title": $0.title, "keys": $0.keys] }
                }
                config[bundleID] = appDict
            }
        }
    }

    var availableApps: [String] {
        var set = Set(config.keys)
        let running = NSWorkspace.shared.runningApplications
        for app in running where app.activationPolicy == .regular {
            if let bid = app.bundleIdentifier, bid != Bundle.main.bundleIdentifier {
                set.insert(bid)
            }
        }
        if !selectedBundleID.isEmpty {
            set.insert(selectedBundleID)
        }
        return set.sorted()
    }

    func displayName(for bundleID: String) -> String {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }),
           let name = running.localizedName {
            return "\(name) (\(bundleID))"
        }
        if bundleID == "com.mitchellh.ghostty" { return "Ghostty (\(bundleID))" }
        if bundleID == "com.google.Chrome" { return "Google Chrome (\(bundleID))" }
        return bundleID
    }

    var currentCategories: [String] {
        guard let appDict = config[selectedBundleID] else { return [] }
        return appDict.keys.sorted()
    }

    func shortcuts(for category: String) -> [[String: String]] {
        return config[selectedBundleID]?[category] ?? []
    }

    func addApp(bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if config[trimmed] == nil {
            config[trimmed] = [:]
        }
        selectedBundleID = trimmed
        isDirty = true
    }

    func addCategory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedBundleID.isEmpty else { return }
        if config[selectedBundleID] == nil {
            config[selectedBundleID] = [:]
        }
        if config[selectedBundleID]?[trimmed] == nil {
            config[selectedBundleID]?[trimmed] = [
                ["title": "New Shortcut", "keys": ""]
            ]
            isDirty = true
        }
    }

    func deleteCategory(name: String) {
        guard !selectedBundleID.isEmpty else { return }
        config[selectedBundleID]?.removeValue(forKey: name)
        isDirty = true
    }

    func addShortcut(category: String) {
        guard !selectedBundleID.isEmpty else { return }
        if config[selectedBundleID] == nil {
            config[selectedBundleID] = [:]
        }
        if config[selectedBundleID]?[category] == nil {
            config[selectedBundleID]?[category] = []
        }
        config[selectedBundleID]?[category]?.append(["title": "New Shortcut", "keys": ""])
        isDirty = true
    }

    func updateShortcut(category: String, index: Int, title: String, keys: String) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        items[index] = ["title": title, "keys": keys]
        config[selectedBundleID]?[category] = items
        isDirty = true
    }

    func deleteShortcut(category: String, index: Int) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        items.remove(at: index)
        config[selectedBundleID]?[category] = items
        isDirty = true
    }

    func insertModifier(_ mod: String, category: String, index: Int) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        var keys = items[index]["keys"] ?? ""
        let modifiers: Set<Character> = ["⌃", "⌥", "⇧", "⌘"]
        let endsWithModifier = keys.last.map { modifiers.contains($0) } ?? false

        if mod == "Space" {
            keys += (keys.isEmpty || endsWithModifier ? "Space" : " Space")
        } else if mod == "Esc" {
            keys += (keys.isEmpty || endsWithModifier ? "Esc" : " Esc")
        } else {
            keys += mod
        }
        items[index]["keys"] = keys
        config[selectedBundleID]?[category] = items
        isDirty = true
    }

    func save() {
        do {
            try CustomShortcutsManager.shared.saveConfig(config)
            isDirty = false
        } catch {
            print("Error saving shortcuts config: \(error)")
        }
    }

    func revert() {
        reload(selecting: selectedBundleID)
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
        if !AppSettings.shared.isPinned {
            HUDWindowController.shared.hide()
        }

        // If target app exists, activate it
        if let app = targetApp {
            app.activate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let axElement = item.axElement {
                AXUIElementPerformAction(axElement, kAXPressAction as CFString)
            } else if let app = targetApp {
                self.synthesizeKeystrokes(keys: item.keys, pid: app.processIdentifier)
            } else {
                // Global shortcut execution: post to active HID system
                self.synthesizeGlobalKeystrokes(keys: item.keys)
            }
        }
    }

    private func synthesizeGlobalKeystrokes(keys: String) {
        let parts = keys.components(separatedBy: " ").filter { !$0.isEmpty && $0 != "/" }
        var delay = 0.0
        let source = CGEventSource(stateID: .hidSystemState)

        for part in parts {
            if let (code, flags) = parseChord(part) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
                       let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) {
                        down.flags = flags
                        up.flags = flags
                        down.post(tap: .cghidEventTap)
                        up.post(tap: .cghidEventTap)
                    }
                }
                delay += 0.025
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

// MARK: - Search State with 2D Navigation (Columns & Items) & Hover

class SearchState: ObservableObject {
    @Published var query: String = "" {
        didSet {
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }
    @Published var selectedGroupIndex: Int = 0
    @Published var selectedItemIndex: Int = 0
    @Published var hoveredItemId: UUID? = nil
    @Published var selectedScope: HUDScope = .activeApp {
        didSet {
            query = ""
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }
}

// MARK: - Auto-Focusing Native Search Field with 2D Arrow Navigation

struct SearchBarView: NSViewRepresentable {
    @Binding var text: String
    var onMoveDown: () -> Void
    var onMoveUp: () -> Void
    var onMoveLeft: () -> Void
    var onMoveRight: () -> Void
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
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onMoveDown()
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onMoveUp()
                return true
            }
            if commandSelector == #selector(NSResponder.moveLeft(_:)) {
                parent.onMoveLeft()
                return true
            }
            if commandSelector == #selector(NSResponder.moveRight(_:)) {
                parent.onMoveRight()
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            }
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
        tf.placeholderString = "Search shortcuts... (↑/↓/←/→ to navigate, Enter to run, Esc to close)"
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

// MARK: - Key Token Parsing, Styling & Modifier Legend

struct KeyToken {
    let text: String
    let color: Color
    let isSpecial: Bool
}

struct KeyTokenParser {
    static let specialSymbols: Set<Character> = ["⌘", "⇧", "⌥", "⌃", "⎋", "⇥", "↩", "⌫", "␣", "←", "→", "↑", "↓", "⇪", "⏏"]

    static func parse(_ keys: String) -> [KeyToken] {
        var tokens: [String] = []
        var idx = keys.startIndex

        while idx < keys.endIndex {
            let ch = keys[idx]
            if ch == " " {
                idx = keys.index(after: idx)
                continue
            }
            if specialSymbols.contains(ch) {
                tokens.append(String(ch))
                idx = keys.index(after: idx)
            } else {
                var word = ""
                while idx < keys.endIndex && !specialSymbols.contains(keys[idx]) && keys[idx] != " " {
                    word.append(keys[idx])
                    idx = keys.index(after: idx)
                }
                if !word.isEmpty {
                    tokens.append(word)
                }
            }
        }

        return tokens.map { token in
            let (color, isSpecial) = styleForToken(token)
            return KeyToken(text: token, color: color, isSpecial: isSpecial)
        }
    }

    static func styleForToken(_ token: String) -> (color: Color, isSpecial: Bool) {
        let lower = token.lowercased()
        switch lower {
        case "⌘", "cmd", "command":
            return (Color(red: 0.35, green: 0.65, blue: 1.0), true)       // Vibrant Blue
        case "⌥", "opt", "option", "alt":
            return (Color(red: 1.0, green: 0.62, blue: 0.20), true)      // Warm Orange
        case "⌃", "ctrl", "control":
            return (Color(red: 0.78, green: 0.48, blue: 1.0), true)       // Purple / Mauve
        case "⇧", "shift":
            return (Color(red: 0.30, green: 0.86, blue: 0.55), true)      // Emerald Green
        case "⎋", "esc", "escape":
            return (Color(red: 1.0, green: 0.38, blue: 0.45), true)       // Coral / Rose
        case "␣", "space":
            return (Color(red: 0.28, green: 0.82, blue: 0.90), true)      // Cyan / Teal
        case "⇥", "tab":
            return (Color(red: 0.96, green: 0.82, blue: 0.30), true)      // Amber Gold
        case "↩", "enter", "return":
            return (Color(red: 0.45, green: 0.76, blue: 0.98), true)      // Sky Blue
        case "⌫", "delete", "backspace":
            return (Color(red: 0.95, green: 0.42, blue: 0.42), true)      // Salmon Red
        case "←", "→", "↑", "↓", "left", "right", "up", "down":
            return (Color(red: 0.88, green: 0.88, blue: 0.92), true)      // Crisp White-Silver
        default:
            return (Color.white.opacity(0.92), false)                      // Standard key letter/digit
        }
    }
}

struct ModifierLegendItem: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let color: Color
}

let modifierLegendItems: [ModifierLegendItem] = [
    ModifierLegendItem(symbol: "⌘", name: "Command", color: Color(red: 0.35, green: 0.65, blue: 1.0)),
    ModifierLegendItem(symbol: "⇧", name: "Shift", color: Color(red: 0.30, green: 0.86, blue: 0.55)),
    ModifierLegendItem(symbol: "⌥", name: "Option", color: Color(red: 1.0, green: 0.62, blue: 0.20)),
    ModifierLegendItem(symbol: "⌃", name: "Control", color: Color(red: 0.78, green: 0.48, blue: 1.0)),
    ModifierLegendItem(symbol: "⎋", name: "Esc", color: Color(red: 1.0, green: 0.38, blue: 0.45)),
    ModifierLegendItem(symbol: "␣", name: "Space", color: Color(red: 0.28, green: 0.82, blue: 0.90)),
    ModifierLegendItem(symbol: "⇥", name: "Tab", color: Color(red: 0.96, green: 0.82, blue: 0.30)),
    ModifierLegendItem(symbol: "↩", name: "Return", color: Color(red: 0.45, green: 0.76, blue: 0.98))
]

// MARK: - Shortcut Row View with Theme & Hover Polish

struct ShortcutRow: View {
    let item: ShortcutItem
    let isSelected: Bool
    let isHovered: Bool
    let accentColor: Color
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        let tokens = KeyTokenParser.parse(item.keys)

        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? .white : .white.opacity(0.88)))
                    .lineLimit(1)

                Spacer(minLength: 8)

                // Distinct Key Token Badges
                HStack(spacing: 3) {
                    ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                        Text(token.text)
                            .font(.system(size: token.isSpecial ? 11 : 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, token.isSpecial ? 5 : 4)
                            .padding(.vertical, 2)
                            .foregroundColor(isSelected ? .black : token.color)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? token.color : (token.isSpecial ? token.color.opacity(0.18) : Color.white.opacity(0.12)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isSelected ? Color.clear : (token.isSpecial ? token.color.opacity(0.40) : Color.white.opacity(0.20)), lineWidth: 0.75)
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? accentColor.opacity(0.25) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? accentColor.opacity(0.85) : (isHovered ? accentColor.opacity(0.35) : Color.clear), lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - HUD Scope Enum

enum HUDScope: Hashable, Identifiable {
    case activeApp
    case ghosttyTool(category: String)
    case aerospace
    case macos

    var id: String {
        switch self {
        case .activeApp: return "activeApp"
        case .ghosttyTool(let category): return "ghostty:\(category)"
        case .aerospace: return "aerospace"
        case .macos: return "macos"
        }
    }

    var title: String {
        switch self {
        case .activeApp: return "Active App"
        case .ghosttyTool(let category): return category
        case .aerospace: return "AeroSpace Tiling"
        case .macos: return "macOS System"
        }
    }
}

// MARK: - SwiftUI HUD View

struct HUDView: View {
    let appName: String
    let bundleID: String
    let appIcon: NSImage?
    let groups: [ShortcutGroup]
    let onExecute: (ShortcutItem) -> Void
    let onDismiss: () -> Void

    @ObservedObject var searchState: SearchState
    @ObservedObject var settings = AppSettings.shared

    var currentScopeGroups: [ShortcutGroup] {
        switch searchState.selectedScope {
        case .activeApp:
            if bundleID == "com.mitchellh.ghostty" {
                // Filter to only categories marked "Shown on Main"
                return groups.filter { settings.isGhosttyCategoryShownOnMain($0.title) }
            }
            return groups
        case .ghosttyTool(let catName):
            return groups.filter { $0.title == catName }
        case .aerospace:
            return AeroSpaceConfigParser.parse()
        case .macos:
            return MacOSGlobalShortcuts.getGroups()
        }
    }

    var filteredGroups: [ShortcutGroup] {
        let q = searchState.query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            return currentScopeGroups
        }
        return currentScopeGroups.compactMap { group in
            let filteredItems = group.items.filter {
                $0.title.lowercased().contains(q) || $0.keys.lowercased().contains(q)
            }
            return filteredItems.isEmpty ? nil : ShortcutGroup(title: group.title, items: filteredItems)
        }
    }

    var currentGroupIndex: Int {
        guard !filteredGroups.isEmpty else { return 0 }
        return min(max(0, searchState.selectedGroupIndex), filteredGroups.count - 1)
    }

    var currentItemIndex: Int {
        guard !filteredGroups.isEmpty else { return 0 }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return 0 }
        return min(max(0, searchState.selectedItemIndex), grp.items.count - 1)
    }

    var currentSelectedItem: ShortcutItem? {
        guard !filteredGroups.isEmpty else { return nil }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return nil }
        return grp.items[currentItemIndex]
    }

    private func executeCurrentSelection() {
        if let item = currentSelectedItem {
            onExecute(item)
        }
    }

    private func moveSelectionDown() {
        guard !filteredGroups.isEmpty else { return }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return }
        if searchState.selectedItemIndex < grp.items.count - 1 {
            searchState.selectedItemIndex += 1
        }
    }

    private func moveSelectionUp() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedItemIndex > 0 {
            searchState.selectedItemIndex -= 1
        }
    }

    private func moveSelectionRight() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedGroupIndex < filteredGroups.count - 1 {
            searchState.selectedGroupIndex += 1
            let newGrp = filteredGroups[searchState.selectedGroupIndex]
            if !newGrp.items.isEmpty {
                searchState.selectedItemIndex = min(searchState.selectedItemIndex, newGrp.items.count - 1)
            } else {
                searchState.selectedItemIndex = 0
            }
        }
    }

    private func moveSelectionLeft() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedGroupIndex > 0 {
            searchState.selectedGroupIndex -= 1
            let newGrp = filteredGroups[searchState.selectedGroupIndex]
            if !newGrp.items.isEmpty {
                searchState.selectedItemIndex = min(searchState.selectedItemIndex, newGrp.items.count - 1)
            } else {
                searchState.selectedItemIndex = 0
            }
        }
    }

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Drag Header / Search Bar
            HStack(spacing: 12) {
                // Scope Switcher Dropdown Menu
                Menu {
                    Button(action: {
                        searchState.selectedScope = .activeApp
                    }) {
                        HStack {
                            if let icon = appIcon {
                                Image(nsImage: icon)
                            }
                            Text(bundleID == "com.mitchellh.ghostty" ? "Ghostty (Main)" : appName)
                        }
                    }

                    // Ghostty TUI Sub-profiles
                    if bundleID == "com.mitchellh.ghostty" {
                        Menu("Terminal Tools") {
                            ForEach(groups) { grp in
                                Button(action: {
                                    searchState.selectedScope = .ghosttyTool(category: grp.title)
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        Text(grp.title)
                                    }
                                }
                            }
                        }
                    }

                    Button(action: {
                        searchState.selectedScope = .aerospace
                    }) {
                        HStack {
                            Image(systemName: "macwindow.on.rectangle")
                            Text("AeroSpace Tiling")
                        }
                    }

                    Button(action: {
                        searchState.selectedScope = .macos
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("macOS System")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        switch searchState.selectedScope {
                        case .activeApp:
                            if let icon = appIcon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text(bundleID == "com.mitchellh.ghostty" ? "Ghostty (Main)" : appName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        case .ghosttyTool(let catName):
                            Image(systemName: "terminal")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(accent)
                            Text("Ghostty: \(catName)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        case .aerospace:
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(accent)
                            Text("AeroSpace Tiling")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        case .macos:
                            Image(systemName: "apple.logo")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(accent)
                            Text("macOS System")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // High-contrast native dropdown chevron pill
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 18, height: 18)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.95))
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.32), lineWidth: 1.2)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())

                Spacer()

                // Search Field Container
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    SearchBarView(
                        text: $searchState.query,
                        onMoveDown: moveSelectionDown,
                        onMoveUp: moveSelectionUp,
                        onMoveLeft: moveSelectionLeft,
                        onMoveRight: moveSelectionRight,
                        onCommit: executeCurrentSelection,
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
                .frame(width: 420)

                // Pin Button
                Button(action: {
                    settings.isPinned.toggle()
                }) {
                    Image(systemName: settings.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(settings.isPinned ? accent : .gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help(settings.isPinned ? "Unpin HUD (currently stays open while running shortcuts)" : "Pin HUD (keep cheatsheet open while running shortcuts)")

                // Edit Shortcuts Button
                Button(action: {
                    HUDWindowController.shared.hide()
                    SettingsWindowController.shared.openSettings(selectingTab: .shortcuts, bundleID: bundleID)
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Edit shortcuts for \(appName)...")

                // Close Button
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
                if filteredGroups.isEmpty {
                    VStack {
                        Spacer()
                        if !AXIsProcessTrusted() {
                            VStack(spacing: 16) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.orange)

                                Text("Accessibility Permission Required")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("macOS requires Accessibility permission for KeyHUD to auto-detect shortcuts from native apps like \(appName).\n\nIf you already turned it ON in System Settings, click Relaunch KeyHUD below so macOS applies the permission token.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.92))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(maxWidth: 440)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        HUDWindowController.shared.hide()
                                        AppDelegate.shared?.relaunchApp()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Relaunch KeyHUD")
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(accent)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Button(action: {
                                        HUDWindowController.shared.hide()
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "gearshape")
                                            Text("Open Privacy Settings")
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.18))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 4)
                            }
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.16, green: 0.16, blue: 0.20))
                                    .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                            )
                        } else {
                            VStack(spacing: 12) {
                                Text("No shortcuts found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { groupIndex, group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.title.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(accent)
                                        .padding(.bottom, 2)

                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, item in
                                                let isSelected = (currentGroupIndex == groupIndex && currentItemIndex == itemIndex)
                                                let isHovered = (searchState.hoveredItemId == item.id)

                                                ShortcutRow(
                                                    item: item,
                                                    isSelected: isSelected,
                                                    isHovered: isHovered,
                                                    accentColor: accent,
                                                    onSelect: {
                                                        searchState.selectedGroupIndex = groupIndex
                                                        searchState.selectedItemIndex = itemIndex
                                                        onExecute(item)
                                                    },
                                                    onHover: { hovering in
                                                        searchState.hoveredItemId = hovering ? item.id : nil
                                                    }
                                                )
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

            // Bottom Modifiers Legend Bar
            Divider()
                .background(Color.white.opacity(0.12))

            HStack(spacing: 16) {
                Text("MODIFIERS:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.trailing, -4)

                ForEach(modifierLegendItems) { item in
                    HStack(spacing: 4) {
                        Text(item.symbol)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(item.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.color.opacity(0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(item.color.opacity(0.35), lineWidth: 0.75)
                            )

                        Text(item.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
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
        if let p = passedApp, p.bundleIdentifier != Bundle.main.bundleIdentifier && p.bundleIdentifier != "com.apple.loginwindow" {
            return p
        }

        // 1. If AeroSpace is running, query the focused window's PID so we always match the active workspace
        let cli = Process()
        cli.launchPath = "/opt/homebrew/bin/aerospace"
        cli.arguments = ["list-windows", "--focused", "--format", "%{app-pid}"]
        let p = Pipe()
        cli.standardOutput = p
        if (try? cli.run()) != nil {
            cli.waitUntilExit()
            let out = String(data: p.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let pidStr = out, let pid = Int32(pidStr), let app = NSRunningApplication(processIdentifier: pid) {
                if app.bundleIdentifier != Bundle.main.bundleIdentifier && app.bundleIdentifier != "com.apple.loginwindow" {
                    return app
                }
            }
        }

        // 2. macOS frontmost application
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier &&
           front.bundleIdentifier != "com.apple.loginwindow" {
            return front
        }

        // 3. Menu bar owning application
        if let menuBarApp = NSWorkspace.shared.menuBarOwningApplication,
           menuBarApp.bundleIdentifier != Bundle.main.bundleIdentifier &&
           menuBarApp.bundleIdentifier != "com.apple.loginwindow" {
            return menuBarApp
        }

        // 4. Fallback to active regular app
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

        let hudView = HUDView(
            appName: appName,
            bundleID: bundleID,
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
        AppSettings.shared.updateWindowsAppearance()

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                if AppSettings.shared.isPinned {
                    AppSettings.shared.isPinned = false
                } else {
                    self?.hide()
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

// MARK: - Keybinding Editor View & Window Controller

struct KeybindingEditorView: View {
    @ObservedObject var state: EditorState
    @ObservedObject var settings = AppSettings.shared
    var onClose: () -> Void

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accent)

                Text("Keybinding Editor")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // App Dropdown
                HStack(spacing: 6) {
                    Text("App:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Picker("", selection: $state.selectedBundleID) {
                        ForEach(state.availableApps, id: \.self) { app in
                            Text(state.displayName(for: app)).tag(app)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(minWidth: 240)

                    Button(action: {
                        state.autoDetectFromRunningApp(bundleID: state.selectedBundleID)
                        state.isDirty = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Re-detect shortcuts from running application's menu bar")

                    Button(action: {
                        state.isAddingApp.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add new application by bundle identifier")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Actions
                Button("Revert") {
                    state.revert()
                }
                .disabled(!state.isDirty)

                Button("Save Changes") {
                    state.save()
                }
                .disabled(!state.isDirty)
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Inline App Adder Banner
            if state.isAddingApp {
                HStack(spacing: 10) {
                    Text("New Bundle ID:")
                        .font(.system(size: 12, weight: .semibold))
                    TextField("e.g. com.apple.Safari or global", text: $state.newAppBundleID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 250)

                    Button("Add App") {
                        if !state.newAppBundleID.isEmpty {
                            state.addApp(bundleID: state.newAppBundleID)
                            state.newAppBundleID = ""
                            state.isAddingApp = false
                        }
                    }
                    Button("Cancel") {
                        state.newAppBundleID = ""
                        state.isAddingApp = false
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(accent.opacity(0.12))

                Divider()
            }

            // Categories & Shortcuts Scroll View
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Category adder banner
                    HStack {
                        if state.isAddingCategory {
                            HStack(spacing: 8) {
                                TextField("Category Name (e.g. Navigation & Tabs)", text: $state.newCategoryName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 240)

                                Button("Add") {
                                    if !state.newCategoryName.isEmpty {
                                        state.addCategory(name: state.newCategoryName)
                                        state.newCategoryName = ""
                                        state.isAddingCategory = false
                                    }
                                }
                                Button("Cancel") {
                                    state.newCategoryName = ""
                                    state.isAddingCategory = false
                                }
                            }
                        } else {
                            Button(action: { state.isAddingCategory = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.rectangle")
                                    Text("Add Category")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(accent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()

                        if state.isDirty {
                            Text("Unsaved Changes")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.orange)
                        }
                    }
                    .padding(.top, 4)

                    if state.currentCategories.isEmpty {
                        if !AXIsProcessTrusted() {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)
                                Text("Accessibility Permission Required")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("macOS requires Accessibility access for KeyHUD to auto-detect menus for \(state.displayName(for: state.selectedBundleID)).\n\nPlease toggle KeyHUD ON in System Settings → Privacy & Security → Accessibility.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 420)
                                Button("Open Privacy & Security Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                Text("No shortcut categories configured for \(state.selectedBundleID).")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("Click '+ Add Category' above to create custom shortcuts.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    } else {
                        ForEach(state.currentCategories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                // Category Header
                                HStack(spacing: 10) {
                                    Text(category.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(accent)

                                    if state.selectedBundleID == "com.mitchellh.ghostty" {
                                        let isShownOnMain = settings.isGhosttyCategoryShownOnMain(category)
                                        Button(action: {
                                            settings.toggleGhosttyCategoryOnMain(category)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: isShownOnMain ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(isShownOnMain ? Color.green : .secondary)
                                                    .font(.system(size: 11))
                                                Text(isShownOnMain ? "Shown on Main" : "Sub-menu Only")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(isShownOnMain ? .primary : .secondary)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isShownOnMain ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Toggle whether this category appears on Ghostty's main combined cheatsheet")
                                    }

                                    Spacer()

                                    Button(action: {
                                        state.deleteCategory(name: category)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Delete Category")
                                }

                                Divider()

                                // Shortcuts List
                                let items = state.shortcuts(for: category)
                                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                    let currentTitle = item["title"] ?? ""
                                    let currentKeys = item["keys"] ?? ""

                                    HStack(spacing: 8) {
                                        TextField("Title", text: Binding(
                                            get: { currentTitle },
                                            set: { state.updateShortcut(category: category, index: index, title: $0, keys: currentKeys) }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(minWidth: 160)

                                        TextField("Keys", text: Binding(
                                            get: { currentKeys },
                                            set: { state.updateShortcut(category: category, index: index, title: currentTitle, keys: $0) }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 130)

                                        // Modifier Quick-Insert Pills with Matching Colors
                                        HStack(spacing: 3) {
                                            ForEach([
                                                (glyph: "⌃", label: "⌃", color: Color(red: 0.78, green: 0.48, blue: 1.0)),
                                                (glyph: "⌥", label: "⌥", color: Color(red: 1.0, green: 0.62, blue: 0.20)),
                                                (glyph: "⇧", label: "⇧", color: Color(red: 0.30, green: 0.86, blue: 0.55)),
                                                (glyph: "⌘", label: "⌘", color: Color(red: 0.35, green: 0.65, blue: 1.0))
                                            ], id: \.glyph) { item in
                                                Button(action: {
                                                    state.insertModifier(item.glyph, category: category, index: index)
                                                }) {
                                                    Text(item.label)
                                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                        .foregroundColor(item.color)
                                                        .frame(width: 22, height: 20)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(item.color.opacity(0.18))
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .stroke(item.color.opacity(0.40), lineWidth: 0.75)
                                                        )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }

                                            Button(action: {
                                                state.insertModifier("Space", category: category, index: index)
                                            }) {
                                                Text("␣ Space")
                                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(Color(red: 0.28, green: 0.82, blue: 0.90))
                                                    .padding(.horizontal, 5)
                                                    .frame(height: 20)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(Color(red: 0.28, green: 0.82, blue: 0.90).opacity(0.18))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .stroke(Color(red: 0.28, green: 0.82, blue: 0.90).opacity(0.40), lineWidth: 0.75)
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Button(action: {
                                                state.insertModifier("Esc", category: category, index: index)
                                            }) {
                                                Text("⎋ Esc")
                                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.45))
                                                    .padding(.horizontal, 5)
                                                    .frame(height: 20)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(Color(red: 1.0, green: 0.38, blue: 0.45).opacity(0.18))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .stroke(Color(red: 1.0, green: 0.38, blue: 0.45).opacity(0.40), lineWidth: 0.75)
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }

                                        // Live Tokenized Badge Preview
                                        HStack(spacing: 2) {
                                            let tokens = KeyTokenParser.parse(currentKeys)
                                            if tokens.isEmpty {
                                                Text("—")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            } else {
                                                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                                                    Text(token.text)
                                                        .font(.system(size: token.isSpecial ? 10 : 9, weight: .bold, design: .monospaced))
                                                        .padding(.horizontal, token.isSpecial ? 4 : 3)
                                                        .padding(.vertical, 1)
                                                        .foregroundColor(token.color)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 3)
                                                                .fill(token.color.opacity(0.18))
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 3)
                                                                .stroke(token.color.opacity(0.40), lineWidth: 0.6)
                                                        )
                                                }
                                            }
                                        }
                                        .frame(minWidth: 70, alignment: .leading)

                                        Button(action: {
                                            state.deleteShortcut(category: category, index: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Delete Shortcut")
                                    }
                                }

                                // Add Shortcut row button
                                Button(action: {
                                    state.addShortcut(category: category)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Add Shortcut")
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(accent)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 4)
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Modifier Legend Bar
            HStack(spacing: 14) {
                Text("MODIFIERS:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.trailing, -4)

                ForEach(modifierLegendItems) { item in
                    HStack(spacing: 4) {
                        Text(item.symbol)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(item.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.color.opacity(0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(item.color.opacity(0.35), lineWidth: 0.75)
                            )

                        Text(item.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Footer
            HStack {
                Text("Edits persist to ~/.config/keyhud/custom_shortcuts.json")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Done") {
                    if state.isDirty {
                        state.save()
                    }
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 650, minHeight: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

class KeybindingEditorWindowController: NSWindowController {
    static let shared = KeybindingEditorWindowController()
    let editorState = EditorState()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 580),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyHUD Keybinding Editor"
        window.collectionBehavior = [.moveToActiveSpace]
        window.minSize = NSSize(width: 600, height: 440)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let view = KeybindingEditorView(state: editorState) { [weak self] in
            self?.close()
        }
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func openEditor(bundleID: String? = nil) {
        editorState.reload(selecting: bundleID)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        var current = AXIsProcessTrusted()
        if !current {
            // Live probe: test whether AX can read any running app
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
        if isAccessibilityGranted != current {
            DispatchQueue.main.async {
                self.isAccessibilityGranted = current
            }
        }
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts & Editor"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .shortcuts: return "keyboard"
        }
    }
}

// MARK: - Native Mac Settings View

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var perm = PermissionChecker.shared
    @ObservedObject var editorState = EditorState.shared
    var onClose: () -> Void

    var selectedTab: SettingsTab {
        SettingsTab(rawValue: settings.selectedSettingsTab) ?? .general
    }

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Top Tab Navigation Bar
            HStack(spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        settings.selectedSettingsTab = tab.rawValue
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selectedTab == tab ? accent : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.75))

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case .general:
                    generalTabView
                case .appearance:
                    appearanceTabView
                case .shortcuts:
                    shortcutsEditorTabView
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer Actions
            HStack {
                Button("Reset Defaults") {
                    settings.widthPercent = 75
                    settings.heightPercent = 65
                    settings.triggerType = 0
                    settings.holdDuration = 0.35
                    settings.accentTheme = AccentTheme.cyan.rawValue
                    settings.appearanceMode = ColorSchemeMode.dark.rawValue
                    settings.isPinned = false
                    HUDWindowController.shared.applyScreenPercentageFrame()
                }

                Spacer()

                Button("Done") {
                    HUDWindowController.shared.applyScreenPercentageFrame()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .frame(minWidth: 700, minHeight: 560)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            perm.refresh()
        }
    }

    // MARK: - General Tab View
    private var generalTabView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // System Permissions Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("SYSTEM PERMISSIONS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        if perm.isAccessibilityGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Accessibility Access")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Granted")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.16))
                                        .cornerRadius(4)
                                }
                                Text("KeyHUD is authorized to auto-detect shortcuts from Chrome, Safari, and other Mac apps, and execute click actions.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Check Status") {
                                perm.refresh()
                            }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Accessibility Access")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Permission Required")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.16))
                                        .cornerRadius(4)
                                }
                                Text("If already toggled ON in System Settings, click Relaunch KeyHUD below so macOS applies the permission token.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Button("Relaunch KeyHUD") {
                                    AppDelegate.shared?.relaunchApp()
                                }

                                Button("Open Settings") {
                                    HUDWindowController.shared.hide()
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(perm.isAccessibilityGranted ? Color.green.opacity(0.08) : Color.orange.opacity(0.12))
                    .cornerRadius(8)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Activation Trigger & Behavior Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACTIVATION TRIGGER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(TriggerType.allCases) { type in
                            Button(action: {
                                settings.triggerType = type.rawValue
                            }) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: settings.triggerType == type.rawValue ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(settings.triggerType == type.rawValue ? settings.currentAccentColor : .secondary)
                                        .font(.system(size: 14))
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.title)
                                            .font(.system(size: 13, weight: settings.triggerType == type.rawValue ? .semibold : .regular))
                                            .foregroundColor(.primary)
                                        Text(type.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    if settings.triggerType == TriggerType.singleHold.rawValue || settings.triggerType == TriggerType.doubleTapAndHold.rawValue {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Command Hold Delay")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int(settings.holdDuration * 1000)) ms")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(settings.currentAccentColor)
                            }
                            Slider(value: $settings.holdDuration, in: 0.15...0.80, step: 0.05)
                        }
                        .padding(.top, 4)
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // Launch at Login Toggle
                    Button(action: {
                        settings.launchAtLogin.toggle()
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.launchAtLogin ? "checkmark.square.fill" : "square")
                                .foregroundColor(settings.launchAtLogin ? settings.currentAccentColor : .secondary)
                                .font(.system(size: 15))
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at Login (Start on Boot)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Automatically start KeyHUD in the background when logging into your Mac.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .padding(.vertical, 2)

                    // Persistent Pin Toggle
                    Button(action: {
                        settings.isPinned.toggle()
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.isPinned ? "checkmark.square.fill" : "square")
                                .foregroundColor(settings.isPinned ? settings.currentAccentColor : .secondary)
                                .font(.system(size: 15))
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Persistent Pin Mode")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Keep the HUD floating on screen even after running shortcuts, ideal for multi-monitor setups or rapid reference.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("Global shortcut ⌘⇧/ (Cmd+Shift+/) also activates KeyHUD at any time.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(18)
        }
    }

    // MARK: - Appearance Tab View
    private var appearanceTabView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Color Scheme Mode Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("APPEARANCE THEME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(ColorSchemeMode.allCases) { mode in
                            Button(action: {
                                settings.appearanceMode = mode.rawValue
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: mode == .automatic ? "circle.righthalf.filled" : (mode == .light ? "sun.max.fill" : "moon.fill"))
                                        .font(.system(size: 13))
                                    Text(mode.rawValue)
                                        .font(.system(size: 13, weight: settings.appearanceMode == mode.rawValue ? .semibold : .regular))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundColor(settings.appearanceMode == mode.rawValue ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(settings.appearanceMode == mode.rawValue ? settings.currentAccentColor : Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Accent Theme Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACCENT THEME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button(action: {
                                settings.accentTheme = theme.rawValue
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 26, height: 26)
                                        if settings.accentTheme == theme.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    Text(theme.rawValue)
                                        .font(.system(size: 11, weight: settings.accentTheme == theme.rawValue ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(settings.accentTheme == theme.rawValue ? theme.color.opacity(0.18) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Window Sizing Section (Moved to Appearance)
                VStack(alignment: .leading, spacing: 10) {
                    Text("WINDOW SIZE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Horizontal (% of screen)")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(settings.widthPercent))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(settings.currentAccentColor)
                        }
                        Slider(value: $settings.widthPercent, in: 25...100, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Vertical (% of screen)")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(settings.heightPercent))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(settings.currentAccentColor)
                        }
                        Slider(value: $settings.heightPercent, in: 25...100, step: 1)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(18)
        }
    }

    // MARK: - Shortcuts & Editor Tab View
    private var shortcutsEditorTabView: some View {
        VStack(spacing: 0) {
            // Quick Tools Bar
            HStack(spacing: 12) {
                Button("Open JSON Config...") {
                    AppDelegate.shared?.openConfig()
                }

                Button("Import File (.json / .keyclu)...") {
                    AppDelegate.shared?.promptImportFile()
                }

                Button("Auto-Detect Configs") {
                    AppDelegate.shared?.autoDetectAction()
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Embedded Keybinding Editor
            KeybindingEditorView(state: editorState) {
                // In-tab dismiss handler
            }
        }
    }
}

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyHUD Settings & Keybinding Editor"
        window.collectionBehavior = [.moveToActiveSpace]
        window.minSize = NSSize(width: 680, height: 520)
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

    func openSettings(selectingTab: SettingsTab = .general, bundleID: String? = nil) {
        AppSettings.shared.selectedSettingsTab = selectingTab.rawValue
        if let bid = bundleID {
            EditorState.shared.reload(selecting: bid)
        }
        AppSettings.shared.updateWindowsAppearance()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - HotKey & Command Listener

class HotKeyManager {
    static let shared = HotKeyManager()
    private var cmdWorkItem: DispatchWorkItem?
    private var lastTapTimes: [Date] = []
    private let tapWindow: TimeInterval = 0.4
    private var isCmdCurrentlyDown = false
    private var shouldIgnoreNextCmdUp = false

    func start() {
        // Global monitors (when other applications are active)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 44 && flags.contains(.command) && flags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
            }
        }

        // Local monitors (when KeyHUD is active / overlay is open)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 44 && flags.contains(.command) && flags.contains(.shift) {
                DispatchQueue.main.async {
                    HUDWindowController.shared.toggle()
                }
                return nil
            }
            return event
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isOnlyCmd = flags == .command

        if isOnlyCmd {
            if !isCmdCurrentlyDown {
                isCmdCurrentlyDown = true
                onCmdDown()
            }
        } else {
            if isCmdCurrentlyDown {
                isCmdCurrentlyDown = false
                onCmdUp()
            }
            cmdWorkItem?.cancel()
            cmdWorkItem = nil
        }
    }

    private func onCmdDown() {
        let now = Date()
        lastTapTimes = lastTapTimes.filter { now.timeIntervalSince($0) < tapWindow }

        let trigger = TriggerType(rawValue: AppSettings.shared.triggerType) ?? .doubleTapAndHold
        let holdSec = AppSettings.shared.holdDuration

        switch trigger {
        case .singleHold:
            let work = DispatchWorkItem { [weak self] in
                self?.shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }
            cmdWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + holdSec, execute: work)

        case .doubleTap:
            if lastTapTimes.count >= 1 {
                lastTapTimes.removeAll()
                shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }

        case .tripleTap:
            if lastTapTimes.count >= 2 {
                lastTapTimes.removeAll()
                shouldIgnoreNextCmdUp = true
                HUDWindowController.shared.toggle()
            }

        case .doubleTapAndHold:
            if lastTapTimes.count >= 1 {
                let holdDelay = max(0.08, holdSec * 0.35)
                let work = DispatchWorkItem { [weak self] in
                    self?.shouldIgnoreNextCmdUp = true
                    HUDWindowController.shared.toggle()
                }
                cmdWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + holdDelay, execute: work)
            }

        case .hotkeyOnly:
            // Modifier hold/tap is disabled; ⌘⇧/ is monitored exclusively
            break
        }
    }

    private func onCmdUp() {
        if shouldIgnoreNextCmdUp {
            shouldIgnoreNextCmdUp = false
            return
        }
        lastTapTimes.append(Date())
    }
}

// MARK: - App Delegate & Menu Controller

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static var shared: AppDelegate?
    var statusItem: NSStatusItem?
    var toggleMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.circle", accessibilityDescription: "KeyHUD")
        }

        let menu = NSMenu()
        menu.delegate = self

        let toggleItem = NSMenuItem(title: "Toggle KeyHUD", action: #selector(toggleHUD), keyEquivalent: "?")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        self.toggleMenuItem = toggleItem
        menu.addItem(toggleItem)
        updateToggleMenuItemTitle()

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Edit Keybindings...", action: #selector(openKeybindingEditor), keyEquivalent: "k"))
        menu.addItem(NSMenuItem(title: "Relaunch KeyHUD", action: #selector(relaunchApp), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Import Shortcuts File... (.json / .keyclu)", action: #selector(importFileAction), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Auto-Detect from Local Configs", action: #selector(autoDetectAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Shortcuts JSON...", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyHUD", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu

        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        HotKeyManager.shared.start()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateToggleMenuItemTitle()
    }

    func updateToggleMenuItemTitle() {
        let trigger = TriggerType(rawValue: AppSettings.shared.triggerType) ?? .doubleTapAndHold
        toggleMenuItem?.title = "Toggle KeyHUD (\(trigger.shortBadge))"
    }

    @objc func toggleHUD() {
        HUDWindowController.shared.toggle()
    }

    @objc func openSettings() {
        SettingsWindowController.shared.openSettings()
    }

    @objc func openKeybindingEditor() {
        SettingsWindowController.shared.openSettings(selectingTab: .shortcuts)
    }

    @objc func relaunchApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["/Applications/KeyHUD.app"]
        try? task.run()
        NSApplication.shared.terminate(nil)
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
