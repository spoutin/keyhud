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

class ShortcutConflictDetector {
    static let shared = ShortcutConflictDetector()

    private var globalCache: [String: ConflictSeverity] = [:]

    init() {
        refreshGlobalShortcuts()
    }

    func refreshGlobalShortcuts() {
        var map: [String: ConflictSeverity] = [:]

        // 1. AeroSpace bindings
        for grp in AeroSpaceConfigParser.parse() {
            for item in grp.items {
                for v in ShortcutNormalizer.variants(item.keys) {
                    let canon = ShortcutNormalizer.canonical(v)
                    if !canon.isEmpty && map[canon] == nil {
                        map[canon] = .globalAeroSpace(action: item.title)
                    }
                }
            }
        }

        // 2. macOS System shortcuts
        for grp in MacOSGlobalShortcuts.getGroups() {
            for item in grp.items {
                for v in ShortcutNormalizer.variants(item.keys) {
                    let canon = ShortcutNormalizer.canonical(v)
                    if !canon.isEmpty && map[canon] == nil {
                        map[canon] = .globalMacOS(action: item.title)
                    }
                }
            }
        }

        // 3. KeyHUD activation hotkey
        map[ShortcutNormalizer.canonical("⌘⇧/")] = .globalKeyHUD
        map[ShortcutNormalizer.canonical("⌘⇧?")] = .globalKeyHUD

        self.globalCache = map
    }

    func checkGlobalConflict(keys: String) -> ConflictSeverity? {
        for v in ShortcutNormalizer.variants(keys) {
            let canon = ShortcutNormalizer.canonical(v)
            if let conflict = globalCache[canon] {
                return conflict
            }
        }
        return nil
    }

    func checkInternalConflict(keys: String, currentTitle: String, inCategories categories: [String], shortcutsProvider: (String) -> [[String: String]]) -> ConflictSeverity? {
        let currentVariants = ShortcutNormalizer.variants(keys).map { ShortcutNormalizer.canonical($0) }
        guard !currentVariants.isEmpty else { return nil }

        for cat in categories {
            let items = shortcutsProvider(cat)
            for other in items {
                let otherTitle = other["title"] ?? ""
                if otherTitle == currentTitle { continue }
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

    func allConflicts(for keys: String, currentTitle: String, inCategories categories: [String], shortcutsProvider: (String) -> [[String: String]]) -> [ConflictSeverity] {
        var results: [ConflictSeverity] = []
        if let internalConf = checkInternalConflict(keys: keys, currentTitle: currentTitle, inCategories: categories, shortcutsProvider: shortcutsProvider) {
            results.append(internalConf)
        }
        if let globalConf = checkGlobalConflict(keys: keys) {
            results.append(globalConf)
        }
        return results
    }
}
