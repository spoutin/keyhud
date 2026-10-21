import Foundation
import AppKit

// MARK: - Mapped Keybinding Container

struct MappedKeybinding: Identifiable, Equatable {
    var id: String { "\(appScope)::\(category)::\(shortcut.id)" }
    let shortcut: ShortcutItem
    let category: String
    let appScope: String
}

// MARK: - Key Heatmap State

enum KeyHeatState: Equatable {
    case available
    case assigned(binding: MappedKeybinding)
    case conflict(bindings: [MappedKeybinding])

    var isAssigned: Bool {
        switch self {
        case .assigned: return true
        default: return false
        }
    }

    var isConflict: Bool {
        switch self {
        case .conflict: return true
        default: return false
        }
    }
}

// MARK: - Physical Key Model

struct PhysicalKey: Identifiable, Hashable {
    let id: String
    let glyph: String
    let charValue: String?
    let widthRatio: CGFloat
    let isModifier: Bool
    let isSpecial: Bool

    init(
        id: String,
        glyph: String,
        charValue: String? = nil,
        widthRatio: CGFloat = 1.0,
        isModifier: Bool = false,
        isSpecial: Bool = false
    ) {
        self.id = id
        self.glyph = glyph
        self.charValue = charValue ?? glyph.lowercased()
        self.widthRatio = widthRatio
        self.isModifier = isModifier
        self.isSpecial = isSpecial
    }
}

// MARK: - Keyboard Row Model

struct KeyboardRow: Identifiable {
    let id: Int
    let keys: [PhysicalKey]
}

// MARK: - 75% Mac ANSI Physical Keyboard Layout

struct KeyboardLayout {

    static let standardMac75: [KeyboardRow] = [
        // Row 0: Function Row
        KeyboardRow(id: 0, keys: [
            PhysicalKey(id: "r0_esc", glyph: "esc", charValue: "esc", widthRatio: 1.35, isSpecial: true),
            PhysicalKey(id: "r0_f1", glyph: "F1", charValue: "f1"),
            PhysicalKey(id: "r0_f2", glyph: "F2", charValue: "f2"),
            PhysicalKey(id: "r0_f3", glyph: "F3", charValue: "f3"),
            PhysicalKey(id: "r0_f4", glyph: "F4", charValue: "f4"),
            PhysicalKey(id: "r0_f5", glyph: "F5", charValue: "f5"),
            PhysicalKey(id: "r0_f6", glyph: "F6", charValue: "f6"),
            PhysicalKey(id: "r0_f7", glyph: "F7", charValue: "f7"),
            PhysicalKey(id: "r0_f8", glyph: "F8", charValue: "f8"),
            PhysicalKey(id: "r0_f9", glyph: "F9", charValue: "f9"),
            PhysicalKey(id: "r0_f10", glyph: "F10", charValue: "f10"),
            PhysicalKey(id: "r0_f11", glyph: "F11", charValue: "f11"),
            PhysicalKey(id: "r0_f12", glyph: "F12", charValue: "f12")
        ]),

        // Row 1: Number Row
        KeyboardRow(id: 1, keys: [
            PhysicalKey(id: "r1_grave", glyph: "`", charValue: "`"),
            PhysicalKey(id: "r1_1", glyph: "1", charValue: "1"),
            PhysicalKey(id: "r1_2", glyph: "2", charValue: "2"),
            PhysicalKey(id: "r1_3", glyph: "3", charValue: "3"),
            PhysicalKey(id: "r1_4", glyph: "4", charValue: "4"),
            PhysicalKey(id: "r1_5", glyph: "5", charValue: "5"),
            PhysicalKey(id: "r1_6", glyph: "6", charValue: "6"),
            PhysicalKey(id: "r1_7", glyph: "7", charValue: "7"),
            PhysicalKey(id: "r1_8", glyph: "8", charValue: "8"),
            PhysicalKey(id: "r1_9", glyph: "9", charValue: "9"),
            PhysicalKey(id: "r1_0", glyph: "0", charValue: "0"),
            PhysicalKey(id: "r1_minus", glyph: "-", charValue: "-"),
            PhysicalKey(id: "r1_equal", glyph: "=", charValue: "="),
            PhysicalKey(id: "r1_delete", glyph: "delete", charValue: "delete", widthRatio: 1.6, isSpecial: true)
        ]),

        // Row 2: QWERTY Row
        KeyboardRow(id: 2, keys: [
            PhysicalKey(id: "r2_tab", glyph: "tab", charValue: "tab", widthRatio: 1.6, isSpecial: true),
            PhysicalKey(id: "r2_q", glyph: "Q", charValue: "q"),
            PhysicalKey(id: "r2_w", glyph: "W", charValue: "w"),
            PhysicalKey(id: "r2_e", glyph: "E", charValue: "e"),
            PhysicalKey(id: "r2_r", glyph: "R", charValue: "r"),
            PhysicalKey(id: "r2_t", glyph: "T", charValue: "t"),
            PhysicalKey(id: "r2_y", glyph: "Y", charValue: "y"),
            PhysicalKey(id: "r2_u", glyph: "U", charValue: "u"),
            PhysicalKey(id: "r2_i", glyph: "I", charValue: "i"),
            PhysicalKey(id: "r2_o", glyph: "O", charValue: "o"),
            PhysicalKey(id: "r2_p", glyph: "P", charValue: "p"),
            PhysicalKey(id: "r2_lbracket", glyph: "[", charValue: "["),
            PhysicalKey(id: "r2_rbracket", glyph: "]", charValue: "]"),
            PhysicalKey(id: "r2_backslash", glyph: "\\", charValue: "\\")
        ]),

        // Row 3: Home Row
        KeyboardRow(id: 3, keys: [
            PhysicalKey(id: "r3_caps", glyph: "caps lock", charValue: nil, widthRatio: 1.9, isSpecial: true),
            PhysicalKey(id: "r3_a", glyph: "A", charValue: "a"),
            PhysicalKey(id: "r3_s", glyph: "S", charValue: "s"),
            PhysicalKey(id: "r3_d", glyph: "D", charValue: "d"),
            PhysicalKey(id: "r3_f", glyph: "F", charValue: "f"),
            PhysicalKey(id: "r3_g", glyph: "G", charValue: "g"),
            PhysicalKey(id: "r3_h", glyph: "H", charValue: "h"),
            PhysicalKey(id: "r3_j", glyph: "J", charValue: "j"),
            PhysicalKey(id: "r3_k", glyph: "K", charValue: "k"),
            PhysicalKey(id: "r3_l", glyph: "L", charValue: "l"),
            PhysicalKey(id: "r3_semicolon", glyph: ";", charValue: ";"),
            PhysicalKey(id: "r3_quote", glyph: "'", charValue: "'"),
            PhysicalKey(id: "r3_return", glyph: "return", charValue: "return", widthRatio: 2.1, isSpecial: true)
        ]),

        // Row 4: ZXCV Row
        KeyboardRow(id: 4, keys: [
            PhysicalKey(id: "r4_lshift", glyph: "shift", charValue: nil, widthRatio: 2.4, isModifier: true),
            PhysicalKey(id: "r4_z", glyph: "Z", charValue: "z"),
            PhysicalKey(id: "r4_x", glyph: "X", charValue: "x"),
            PhysicalKey(id: "r4_c", glyph: "C", charValue: "c"),
            PhysicalKey(id: "r4_v", glyph: "V", charValue: "v"),
            PhysicalKey(id: "r4_b", glyph: "B", charValue: "b"),
            PhysicalKey(id: "r4_n", glyph: "N", charValue: "n"),
            PhysicalKey(id: "r4_m", glyph: "M", charValue: "m"),
            PhysicalKey(id: "r4_comma", glyph: ",", charValue: ","),
            PhysicalKey(id: "r4_period", glyph: ".", charValue: "."),
            PhysicalKey(id: "r4_slash", glyph: "/", charValue: "/"),
            PhysicalKey(id: "r4_rshift", glyph: "shift", charValue: nil, widthRatio: 2.4, isModifier: true)
        ]),

        // Row 5: Modifier & Space Row
        KeyboardRow(id: 5, keys: [
            PhysicalKey(id: "r5_fn", glyph: "fn", charValue: nil, widthRatio: 1.1, isModifier: true),
            PhysicalKey(id: "r5_lctrl", glyph: "control", charValue: nil, widthRatio: 1.2, isModifier: true),
            PhysicalKey(id: "r5_lopt", glyph: "option", charValue: nil, widthRatio: 1.3, isModifier: true),
            PhysicalKey(id: "r5_lcmd", glyph: "command ⌘", charValue: nil, widthRatio: 1.6, isModifier: true),
            PhysicalKey(id: "r5_space", glyph: "space", charValue: "space", widthRatio: 6.2, isSpecial: true),
            PhysicalKey(id: "r5_rcmd", glyph: "⌘ command", charValue: nil, widthRatio: 1.6, isModifier: true),
            PhysicalKey(id: "r5_ropt", glyph: "option", charValue: nil, widthRatio: 1.3, isModifier: true),
            PhysicalKey(id: "r5_left", glyph: "◀", charValue: "left", widthRatio: 1.0, isSpecial: true),
            PhysicalKey(id: "r5_updown", glyph: "▲▼", charValue: "up", widthRatio: 1.0, isSpecial: true),
            PhysicalKey(id: "r5_right", glyph: "▶", charValue: "right", widthRatio: 1.0, isSpecial: true)
        ])
    ]

    // MARK: - Key Combo Parsing

    static func parseKeyCombo(_ raw: String) -> (modifiers: NSEvent.ModifierFlags, baseKey: String) {
        let str = raw.trimmingCharacters(in: .whitespaces)
        var flags: NSEvent.ModifierFlags = []

        if str.contains("⌘") || str.lowercased().contains("cmd+") {
            flags.insert(.command)
        }
        if str.contains("⇧") || str.lowercased().contains("shift+") {
            flags.insert(.shift)
        }
        if str.contains("⌥") || str.lowercased().contains("opt+") || str.lowercased().contains("alt+") {
            flags.insert(.option)
        }
        if str.contains("⌃") || str.lowercased().contains("ctrl+") {
            flags.insert(.control)
        }

        // Strip modifier markers to get the base key string
        let clean = str
            .replacingOccurrences(of: "⌘", with: "")
            .replacingOccurrences(of: "⇧", with: "")
            .replacingOccurrences(of: "⌥", with: "")
            .replacingOccurrences(of: "⌃", with: "")
            .replacingOccurrences(of: "cmd+", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "shift+", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "opt+", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "alt+", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ctrl+", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        return (flags, clean)
    }

    // MARK: - Key Evaluation & Heatmap Computation

    static func evaluateKey(
        key: PhysicalKey,
        activeModifiers: NSEvent.ModifierFlags,
        bindings: [MappedKeybinding]
    ) -> KeyHeatState {
        // Modifiers themselves are not triggered by shortcuts
        if key.isModifier || key.charValue == nil {
            return .available
        }

        guard let targetChar = key.charValue?.lowercased() else {
            return .available
        }

        let relevantMods: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let activeFiltered = activeModifiers.intersection(relevantMods)

        let matched = bindings.filter { binding in
            let parsed = parseKeyCombo(binding.shortcut.keys)
            let itemFiltered = parsed.modifiers.intersection(relevantMods)

            guard itemFiltered == activeFiltered else {
                return false
            }

            return keyMatches(itemKey: parsed.baseKey, targetChar: targetChar)
        }

        if matched.isEmpty {
            return .available
        } else if matched.count == 1, let single = matched.first {
            return .assigned(binding: single)
        } else {
            return .conflict(bindings: matched)
        }
    }

    private static func keyMatches(itemKey: String, targetChar: String) -> Bool {
        let cleanItem = itemKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Exact match
        if cleanItem == targetChar {
            return true
        }

        // Special symbol aliases
        switch targetChar {
        case "space":
            return cleanItem == "space" || cleanItem == " " || cleanItem == "␣"
        case "return":
            return cleanItem == "return" || cleanItem == "enter" || cleanItem == "↩"
        case "delete":
            return cleanItem == "delete" || cleanItem == "backspace" || cleanItem == "⌫"
        case "tab":
            return cleanItem == "tab" || cleanItem == "⇥"
        case "esc":
            return cleanItem == "esc" || cleanItem == "escape" || cleanItem == "⎋"
        case "left":
            return cleanItem == "left" || cleanItem == "←" || cleanItem == "arrowleft"
        case "right":
            return cleanItem == "right" || cleanItem == "→" || cleanItem == "arrowright"
        case "up":
            return cleanItem == "up" || cleanItem == "↑" || cleanItem == "arrowup" || cleanItem == "down" || cleanItem == "↓"
        case "/":
            return cleanItem == "/" || cleanItem == "?"
        default:
            return false
        }
    }
}
