import Foundation
import AppKit
import Carbon

// MARK: - Key Combo Decoder for Recording

struct KeyComboDecoder {
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "Tab"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "Esc"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            let keyMap: [Int: String] = [
                0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
                11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
                20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
                29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
                39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
                50: "`"
            ]
            return keyMap[Int(keyCode)] ?? ""
        }
    }

    static func decode(flags: NSEvent.ModifierFlags, keyCode: UInt16) -> (result: String?, isCancel: Bool, isClear: Bool) {
        let cleanFlags = flags.intersection(.deviceIndependentFlagsMask)

        // Bare delete/backspace clears / deletes last token
        if cleanFlags.isEmpty && (Int(keyCode) == kVK_Delete || Int(keyCode) == kVK_ForwardDelete) {
            return ("", false, true)
        }

        let keyStr = keyCodeToString(keyCode)
        guard !keyStr.isEmpty else { return (nil, false, false) }

        var combo = ""
        if cleanFlags.contains(.control) { combo += "⌃" }
        if cleanFlags.contains(.option) { combo += "⌥" }
        if cleanFlags.contains(.shift) { combo += "⇧" }
        if cleanFlags.contains(.command) { combo += "⌘" }

        combo += keyStr
        return (combo, false, false)
    }
}

// MARK: - Shortcut Normalizer & Conflict Detection

struct ShortcutNormalizer {
    static let modifierOrder: [Character] = ["⌃", "⌥", "⇧", "⌘"]

    static func canonical(_ raw: String) -> String {
        var str = raw.trimmingCharacters(in: .whitespaces)
        str = str.replacingOccurrences(of: "ctrl+", with: "⌃")
                 .replacingOccurrences(of: "alt+", with: "⌥")
                 .replacingOccurrences(of: "opt+", with: "⌥")
                 .replacingOccurrences(of: "shift+", with: "⇧")
                 .replacingOccurrences(of: "cmd+", with: "⌘")

        var modifiers: [Character] = []
        var keys: [Character] = []
        let hasCmd = str.contains("⌘")

        for ch in str {
            if modifierOrder.contains(ch) {
                if !modifiers.contains(ch) {
                    modifiers.append(ch)
                }
            } else if ch != " " {
                // If there's no Cmd modifier, an uppercase ASCII letter represents Shift+letter
                if !hasCmd && ch.isASCII && ch.isUppercase && ch.isLetter {
                    if !modifiers.contains("⇧") {
                        modifiers.append("⇧")
                    }
                }
                keys.append(Character(ch.lowercased()))
            }
        }

        modifiers.sort { (a, b) -> Bool in
            let idxA = modifierOrder.firstIndex(of: a) ?? 99
            let idxB = modifierOrder.firstIndex(of: b) ?? 99
            return idxA < idxB
        }

        return String(modifiers) + String(keys)
    }

    static func variants(_ rawKeys: String) -> [String] {
        return rawKeys.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

enum ConflictSeverity: Equatable {
    case duplicateApp(otherTitle: String, category: String)
    case globalAeroSpace(action: String)
    case globalMacOS(action: String)
    case globalKeyHUD
    case standardConvention(action: String)
    case overriddenStandard(action: String)

    var isWarning: Bool {
        switch self {
        case .standardConvention: return false
        default: return true
        }
    }

    var isBenignConvention: Bool {
        switch self {
        case .standardConvention: return true
        default: return false
        }
    }

    var badgeText: String {
        switch self {
        case .duplicateApp(let otherTitle, _):
            return "Conflict: \"\(otherTitle)\""
        case .globalAeroSpace(let act):
            return "Global: AeroSpace (\(act))"
        case .globalMacOS(let act):
            return "Global: macOS (\(act))"
        case .globalKeyHUD:
            return "Global: KeyHUD Hotkey"
        case .standardConvention(let act):
            return "macOS: \(act)"
        case .overriddenStandard(let act):
            return "Overrides: macOS (\(act))"
        }
    }

    var tooltip: String {
        switch self {
        case .duplicateApp(let otherTitle, let cat):
            return "App Conflict: Same shortcut is also assigned to '\(otherTitle)' in '\(cat)'"
        case .globalAeroSpace(let act):
            return "System Conflict: Collides with AeroSpace window tiling command '\(act)'"
        case .globalMacOS(let act):
            return "System Conflict: Collides with macOS System shortcut '\(act)'"
        case .globalKeyHUD:
            return "System Conflict: Collides with KeyHUD toggle hotkey (⌘⇧/)"
        case .standardConvention(let act):
            return "Standard macOS convention: Matches default '\(act)' behavior"
        case .overriddenStandard(let act):
            return "Warning: Overrides standard macOS shortcut '\(act)' for a different function"
        }
    }

    var isGlobal: Bool {
        switch self {
        case .duplicateApp: return false
        default: return true
        }
    }
}

struct ConflictSummaryItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let keys: String
    let conflicts: [ConflictSeverity]
}

// MARK: - Tool & Terminal Domain Isolation Helper

struct ToolDomainHelper {
    static func toolDomain(for category: String) -> String {
        let clean = category.trimmingCharacters(in: .whitespaces)
        // If category has a prefix before a colon, e.g. "Neovim: Edits & Leader" -> "neovim"
        if let colonIdx = clean.firstIndex(of: ":") {
            let prefix = String(clean[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            return prefix.lowercased()
        }
        return clean.lowercased()
    }

    static func areCategoriesInSameDomain(catA: String, catB: String, bundleID: String) -> Bool {
        if catA == catB { return true }

        let isTerminal = bundleID.lowercased().contains("ghostty") ||
                         bundleID.lowercased().contains("terminal") ||
                         bundleID.lowercased().contains("iterm") ||
                         bundleID.lowercased().contains("alacritty") ||
                         bundleID.lowercased().contains("kitty") ||
                         bundleID.lowercased().contains("wezterm")

        // For standard macOS GUI apps, all categories exist simultaneously
        if !isTerminal {
            return true
        }

        // For terminal emulators, distinct TUIs and shells run in mutually exclusive contexts
        let domainA = toolDomain(for: catA)
        let domainB = toolDomain(for: catB)
        return domainA == domainB
    }

    static func areBindingsInConflict(a: MappedKeybinding, b: MappedKeybinding, bundleID: String) -> Bool {
        if a.id == b.id { return false }

        // If one binding is from macOS and the other from an app, check if they share the same standard convention
        let isAMacOS = a.appScope == "macOS"
        let isBMacOS = b.appScope == "macOS"
        if isAMacOS != isBMacOS {
            let appBinding = isAMacOS ? b : a
            let macBinding = isAMacOS ? a : b
            let appTitle = appBinding.shortcut.title.lowercased()
            let macTitle = macBinding.shortcut.title.lowercased()

            // Conforming standard AppKit actions do not conflict
            if (macTitle.contains("hide") && appTitle.contains("hide")) ||
               (macTitle.contains("quit") && (appTitle.contains("quit") || appTitle.contains("exit"))) ||
               (macTitle.contains("close") && appTitle.contains("close")) ||
               (macTitle.contains("minimize") && appTitle.contains("minimi")) ||
               (macTitle.contains("undo") && appTitle.contains("undo")) ||
               (macTitle.contains("redo") && appTitle.contains("redo")) ||
               (macTitle.contains("copy") && appTitle.contains("copy")) ||
               (macTitle.contains("paste") && appTitle.contains("paste")) ||
               (macTitle.contains("settings") && (appTitle.contains("setting") || appTitle.contains("preference"))) {
                return false
            }
            return true
        }

        // Global collisions (AeroSpace) intercept everywhere
        if a.appScope == "AeroSpace" || b.appScope == "AeroSpace" {
            return true
        }

        if a.appScope != b.appScope {
            return false
        }

        return areCategoriesInSameDomain(catA: a.category, catB: b.category, bundleID: bundleID)
    }
}

struct StandardAppConvention {
    let canonicalKey: String
    let actionName: String
    let keywords: [String]
}

class ShortcutConflictDetector {
    static let shared = ShortcutConflictDetector()

    private var daemonCache: [String: ConflictSeverity] = [:]
    private var conventionsCache: [String: StandardAppConvention] = [:]

    init() {
        refreshGlobalShortcuts()
    }

    func refreshGlobalShortcuts() {
        var daemons: [String: ConflictSeverity] = [:]
        var conventions: [String: StandardAppConvention] = [:]

        // 1. AeroSpace bindings (only main mode represents active global hotkeys)
        for grp in AeroSpaceConfigParser.parse(onlyMainMode: true) {
            for item in grp.items {
                for v in ShortcutNormalizer.variants(item.keys) {
                    let canon = ShortcutNormalizer.canonical(v)
                    if !canon.isEmpty && daemons[canon] == nil {
                        daemons[canon] = .globalAeroSpace(action: item.title)
                    }
                }
            }
        }

        // 2. Standard App Conventions (AppKit HIG menu commands)
        let conventionList: [StandardAppConvention] = [
            StandardAppConvention(canonicalKey: "⌘h",  actionName: "Hide Application",        keywords: ["hide"]),
            StandardAppConvention(canonicalKey: "⌥⌘h", actionName: "Hide Others",             keywords: ["hide other", "hide others"]),
            StandardAppConvention(canonicalKey: "⌘q",  actionName: "Quit Application",        keywords: ["quit", "exit"]),
            StandardAppConvention(canonicalKey: "⌘w",  actionName: "Close Window",            keywords: ["close"]),
            StandardAppConvention(canonicalKey: "⌘m",  actionName: "Minimize Window",        keywords: ["minimize", "minimise"]),
            StandardAppConvention(canonicalKey: "⌘`",  actionName: "Cycle Windows",           keywords: ["cycle window", "switch window", "next window", "window"]),
            StandardAppConvention(canonicalKey: "⌘z",  actionName: "Undo",                    keywords: ["undo"]),
            StandardAppConvention(canonicalKey: "⇧⌘z", actionName: "Redo",                    keywords: ["redo"]),
            StandardAppConvention(canonicalKey: "⌘,",  actionName: "Preferences / Settings",  keywords: ["setting", "preference", "option"]),
            StandardAppConvention(canonicalKey: "⌘c",  actionName: "Copy",                    keywords: ["copy"]),
            StandardAppConvention(canonicalKey: "⌘v",  actionName: "Paste",                   keywords: ["paste"]),
            StandardAppConvention(canonicalKey: "⌘x",  actionName: "Cut",                     keywords: ["cut"]),
            StandardAppConvention(canonicalKey: "⌘a",  actionName: "Select All",              keywords: ["select all"])
        ]
        for conv in conventionList {
            let canon = ShortcutNormalizer.canonical(conv.canonicalKey)
            conventions[canon] = conv
        }

        // 3. macOS True Daemon Intercepts (System daemon hotkeys)
        for grp in MacOSGlobalShortcuts.getGroups() {
            if grp.title == "Window & App Management" {
                continue
            }
            for item in grp.items {
                for v in ShortcutNormalizer.variants(item.keys) {
                    let canon = ShortcutNormalizer.canonical(v)
                    if !canon.isEmpty && daemons[canon] == nil {
                        daemons[canon] = .globalMacOS(action: item.title)
                    }
                }
            }
        }

        // 4. KeyHUD activation hotkey
        daemons[ShortcutNormalizer.canonical("⌘⇧/")] = .globalKeyHUD
        daemons[ShortcutNormalizer.canonical("⌘⇧?")] = .globalKeyHUD

        self.daemonCache = daemons
        self.conventionsCache = conventions
    }

    func checkGlobalConflict(keys: String, title: String) -> ConflictSeverity? {
        let titleLower = title.lowercased()

        for v in ShortcutNormalizer.variants(keys) {
            let canon = ShortcutNormalizer.canonical(v)
            if canon.isEmpty { continue }

            // 1. Hard OS daemon intercept (Spotlight, Screenshots, AeroSpace, etc.)
            if let daemonConflict = daemonCache[canon] {
                return daemonConflict
            }

            // 2. Standard AppKit convention
            if let conv = conventionsCache[canon] {
                let matchesIntent = conv.keywords.contains { kw in
                    titleLower.contains(kw)
                }

                if matchesIntent {
                    return .standardConvention(action: conv.actionName)
                } else {
                    return .overriddenStandard(action: conv.actionName)
                }
            }
        }
        return nil
    }

    func checkInternalConflict(
        keys: String,
        currentTitle: String,
        currentCategory: String = "",
        inCategories categories: [String],
        bundleID: String = "",
        shortcutsProvider: (String) -> [[String: String]]
    ) -> ConflictSeverity? {
        let currentVariants = ShortcutNormalizer.variants(keys).map { ShortcutNormalizer.canonical($0) }
        guard !currentVariants.isEmpty else { return nil }

        for cat in categories {
            // Skip categories that are in different execution domains (e.g. zsh-vi-mode vs a TUI in Ghostty)
            if !currentCategory.isEmpty && !ToolDomainHelper.areCategoriesInSameDomain(catA: currentCategory, catB: cat, bundleID: bundleID) {
                continue
            }

            let items = shortcutsProvider(cat)
            for other in items {
                let otherTitle = other["title"] ?? ""
                if otherTitle == currentTitle && cat == currentCategory { continue }
                let otherKeys = other["keys"] ?? ""
                let otherVariants = ShortcutNormalizer.variants(otherKeys).map { ShortcutNormalizer.canonical($0) }

                for cv in currentVariants {
                    if !cv.isEmpty && otherVariants.contains(cv) {
                        return .duplicateApp(otherTitle: otherTitle, category: cat)
                    }
                }
            }
        }
        return nil
    }

    func allConflicts(
        for keys: String,
        currentTitle: String,
        currentCategory: String = "",
        inCategories categories: [String],
        bundleID: String = "",
        shortcutsProvider: (String) -> [[String: String]]
    ) -> [ConflictSeverity] {
        var results: [ConflictSeverity] = []
        if let internalConf = checkInternalConflict(
            keys: keys,
            currentTitle: currentTitle,
            currentCategory: currentCategory,
            inCategories: categories,
            bundleID: bundleID,
            shortcutsProvider: shortcutsProvider
        ) {
            results.append(internalConf)
        }

        let isSystemBundle = bundleID == "com.apple.systempreferences" || bundleID == "global" || bundleID == "macos"
        if !isSystemBundle {
            if let globalConf = checkGlobalConflict(keys: keys, title: currentTitle) {
                results.append(globalConf)
            }
        }
        return results
    }
}
