import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Models

struct ShortcutItem: Identifiable, Equatable {
    var id: String { "\(title)::\(keys)" }
    let title: String
    let keys: String
    var axElement: AXUIElement? = nil

    var isMenuAction: Bool { keys.trimmingCharacters(in: .whitespaces).isEmpty }

    static func == (lhs: ShortcutItem, rhs: ShortcutItem) -> Bool {
        lhs.title == rhs.title && lhs.keys == rhs.keys
    }
}

struct ShortcutGroup: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let items: [ShortcutItem]

    static func == (lhs: ShortcutGroup, rhs: ShortcutGroup) -> Bool {
        lhs.title == rhs.title && lhs.items == rhs.items
    }
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

enum SearchScope: String, CaseIterable, Identifiable {
    case current = "Current View"
    case currentAndSubApps = "Current + Sub-tools"
    case global = "All / Global"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .current: return "macwindow"
        case .currentAndSubApps: return "square.stack.3d.up"
        case .global: return "globe"
        }
    }
}

enum CommandPaletteMode: String, CaseIterable, Identifiable {
    case searchOnly = "During Search Only"
    case always = "Always"
    case off = "Shortcuts Only"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .searchOnly:
            return "Shows menu actions without shortcuts only while typing in the search bar."
        case .always:
            return "Shows all application menu actions in columns at all times."
        case .off:
            return "Only shows menu items that have an assigned keyboard shortcut."
        }
    }
}

// MARK: - HUD Scope Enum

enum HUDScope: Hashable, Identifiable {
    case activeApp
    case ghosttyTool(category: String)
    case runningApp(bundleID: String, name: String, icon: NSImage)
    case aerospace
    case macos

    var id: String {
        switch self {
        case .activeApp: return "activeApp"
        case .ghosttyTool(let category): return "ghostty:\(category)"
        case .runningApp(let bundleID, _, _): return "running:\(bundleID)"
        case .aerospace: return "aerospace"
        case .macos: return "macos"
        }
    }

    var title: String {
        switch self {
        case .activeApp: return "Active App"
        case .ghosttyTool(let category): return category
        case .runningApp(_, let name, _): return name
        case .aerospace: return "AeroSpace Tiling"
        case .macos: return "macOS System"
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
    @Published var defaultSearchScope: String {
        didSet {
            UserDefaults.standard.set(defaultSearchScope, forKey: "defaultSearchScope")
        }
    }
    @Published var commandPaletteMode: String {
        didSet {
            UserDefaults.standard.set(commandPaletteMode, forKey: "commandPaletteMode")
        }
    }
    @Published var widthPercent: Double {
        didSet {
            UserDefaults.standard.set(widthPercent, forKey: "widthPercent")
            HUDWindowController.shared.applyScreenPercentageFrame()
        }
    }
    @Published var heightPercent: Double {
        didSet {
            UserDefaults.standard.set(heightPercent, forKey: "heightPercent")
            HUDWindowController.shared.applyScreenPercentageFrame()
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
    @Published var zebraStriping: Bool {
        didSet {
            UserDefaults.standard.set(zebraStriping, forKey: "zebraStriping")
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

        let savedSearchScope = UserDefaults.standard.string(forKey: "defaultSearchScope")
        self.defaultSearchScope = (savedSearchScope != nil && SearchScope(rawValue: savedSearchScope!) != nil) ? savedSearchScope! : SearchScope.current.rawValue

        let savedPalette = UserDefaults.standard.string(forKey: "commandPaletteMode")
        self.commandPaletteMode = (savedPalette != nil && CommandPaletteMode(rawValue: savedPalette!) != nil) ? savedPalette! : CommandPaletteMode.searchOnly.rawValue

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

        self.zebraStriping = UserDefaults.standard.bool(forKey: "zebraStriping")
        self.isPinned = UserDefaults.standard.bool(forKey: "isPinned")
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled

        let savedHidden = UserDefaults.standard.stringArray(forKey: "ghosttyHiddenCategories")
        if let hidden = savedHidden {
            self.ghosttyHiddenCategories = Set(hidden)
        } else {
            self.ghosttyHiddenCategories = Set(["K9s: Kubernetes", "Lazygit: Git TUI", "Atuin: Shell History", "VisiData: Data Tables"])
        }
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

// MARK: - Bookmarks & Favorites Manager

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    private let storageKey = "bookmarkedShortcuts"

    @Published var bookmarks: [String: Set<String>] = [:]

    init() {
        load()
    }

    func load() {
        if let dict = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String]] {
            var loaded: [String: Set<String>] = [:]
            for (k, v) in dict {
                loaded[k] = Set(v)
            }
            self.bookmarks = loaded
        }
    }

    private func save() {
        var dict: [String: [String]] = [:]
        for (k, v) in bookmarks {
            dict[k] = Array(v).sorted()
        }
        UserDefaults.standard.set(dict, forKey: storageKey)
    }

    func isBookmarked(scopeKey: String, title: String) -> Bool {
        return bookmarks[scopeKey]?.contains(title) ?? false
    }

    func toggleBookmark(scopeKey: String, title: String) {
        var set = bookmarks[scopeKey] ?? Set<String>()
        if set.contains(title) {
            set.remove(title)
        } else {
            set.insert(title)
        }
        bookmarks[scopeKey] = set
        save()
    }

    func bookmarks(for scopeKey: String) -> Set<String> {
        return bookmarks[scopeKey] ?? []
    }
}

// MARK: - Hidden Items Manager

class HiddenItemsManager: ObservableObject {
    static let shared = HiddenItemsManager()
    private let categoriesStorageKey = "hiddenCategoriesByApp"
    private let itemsStorageKey = "hiddenItemsByApp"

    @Published var hiddenCategories: [String: Set<String>] = [:]
    @Published var hiddenItems: [String: Set<String>] = [:]

    init() {
        load()
    }

    func load() {
        if let catDict = UserDefaults.standard.dictionary(forKey: categoriesStorageKey) as? [String: [String]] {
            var loadedCats: [String: Set<String>] = [:]
            for (k, v) in catDict {
                loadedCats[k] = Set(v)
            }
            self.hiddenCategories = loadedCats
        }

        if let itemDict = UserDefaults.standard.dictionary(forKey: itemsStorageKey) as? [String: [String]] {
            var loadedItems: [String: Set<String>] = [:]
            for (k, v) in itemDict {
                loadedItems[k] = Set(v)
            }
            self.hiddenItems = loadedItems
        }
    }

    private func save() {
        var catDict: [String: [String]] = [:]
        for (k, v) in hiddenCategories {
            catDict[k] = Array(v).sorted()
        }
        UserDefaults.standard.set(catDict, forKey: categoriesStorageKey)

        var itemDict: [String: [String]] = [:]
        for (k, v) in hiddenItems {
            itemDict[k] = Array(v).sorted()
        }
        UserDefaults.standard.set(itemDict, forKey: itemsStorageKey)
    }

    private func itemKey(bundleID: String, category: String) -> String {
        return "\(bundleID)::\(category)"
    }

    func isCategoryHidden(bundleID: String, category: String) -> Bool {
        return hiddenCategories[bundleID]?.contains(category) ?? false
    }

    func toggleCategoryHidden(bundleID: String, category: String) {
        var set = hiddenCategories[bundleID] ?? Set<String>()
        if set.contains(category) {
            set.remove(category)
        } else {
            set.insert(category)
        }
        hiddenCategories[bundleID] = set
        save()
    }

    func isItemHidden(bundleID: String, category: String, title: String) -> Bool {
        let key = itemKey(bundleID: bundleID, category: category)
        return hiddenItems[key]?.contains(title) ?? false
    }

    func toggleItemHidden(bundleID: String, category: String, title: String) {
        let key = itemKey(bundleID: bundleID, category: category)
        var set = hiddenItems[key] ?? Set<String>()
        if set.contains(title) {
            set.remove(title)
        } else {
            set.insert(title)
        }
        hiddenItems[key] = set
        save()
    }
}
