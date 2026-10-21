import SwiftUI
import AppKit

// MARK: - Block Menu Item

class BlockMenuItem: NSMenuItem {
    private var handler: () -> Void

    init(title: String, iconName: String? = nil, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(didSelect), keyEquivalent: "")
        self.target = self
        if let icon = iconName {
            self.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelect() {
        handler()
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
    @Published var hoveredItemId: String? = nil
    @Published var selectedScope: HUDScope = .activeApp {
        didSet {
            query = ""
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }
    @Published var scopeHistory: [HUDScope] = []
    @Published var activeSearchScope: SearchScope = .current {
        didSet {
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }
    @Published var showHiddenItems: Bool = false {
        didSet {
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }
    @Published var isCommandPaletteActive: Bool = false {
        didSet {
            selectedGroupIndex = 0
            selectedItemIndex = 0
        }
    }

    var canGoBack: Bool { !scopeHistory.isEmpty }

    func navigateToScope(_ newScope: HUDScope) {
        if selectedScope != newScope {
            scopeHistory.append(selectedScope)
            selectedScope = newScope
        }
    }

    func popScope() -> Bool {
        guard let prev = scopeHistory.popLast() else { return false }
        selectedScope = prev
        return true
    }

    func popToHistoryIndex(_ index: Int) {
        guard index >= 0 && index < scopeHistory.count else { return }
        let target = scopeHistory[index]
        scopeHistory = Array(scopeHistory.prefix(index))
        selectedScope = target
    }

    func clearHistory() {
        scopeHistory.removeAll()
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
    let isBookmarked: Bool
    var isHiddenShortcut: Bool = false
    var isOddRow: Bool = false
    let accentColor: Color
    let onSelect: () -> Void
    let onToggleBookmark: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        let tokens = KeyTokenParser.parse(item.keys)
        let defaultBg: Color = {
            if !AppSettings.shared.zebraStriping {
                return Color.white.opacity(0.03)
            }
            return isOddRow ? Color.white.opacity(0.065) : Color.white.opacity(0.015)
        }()

        HStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(alignment: .center, spacing: 6) {
                    if isHiddenShortcut {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                            .frame(width: 12, height: 12)
                    }

                    // Bookmark Star Icon Button
                    Button(action: onToggleBookmark) {
                        Image(systemName: isBookmarked ? "star.fill" : "star")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isBookmarked ? Color.yellow : Color.white.opacity(isHovered ? 0.35 : 0.0))
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isBookmarked ? "Favorite: Click to remove from pinned ⭐ Favorites column" : "Favorite: Click to pin to ⭐ Favorites column")

                    Text(item.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : (isHiddenShortcut ? .white.opacity(0.40) : (isHovered ? .white : .white.opacity(0.88))))
                        .strikethrough(isHiddenShortcut && !isSelected, color: Color.orange.opacity(0.5))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    // Distinct Key Token Badges or Action Pill
                    if tokens.isEmpty {
                        Text("Action")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(isSelected ? .black : Color.white.opacity(0.60))
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? accentColor : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.15), lineWidth: 0.75)
                            )
                    } else {
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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? accentColor.opacity(0.25) : (isBookmarked ? Color.yellow.opacity(0.06) : (isHovered ? Color.white.opacity(0.08) : defaultBg)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? accentColor.opacity(0.85) : (isHovered ? accentColor.opacity(0.35) : (isBookmarked ? Color.yellow.opacity(0.25) : Color.clear)), lineWidth: 1.2)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - Smart Fuzzy Matcher

struct FuzzyMatcher {
    static func matches(pattern: String, target: String) -> Bool {
        if pattern.isEmpty { return true }
        let pLower = pattern.lowercased()
        let tLower = target.lowercased()

        // Quick check for consecutive substring
        if tLower.contains(pLower) { return true }

        var pIdx = pLower.startIndex
        var tIdx = tLower.startIndex

        while pIdx < pLower.endIndex && tIdx < tLower.endIndex {
            if pLower[pIdx] == tLower[tIdx] {
                pIdx = pLower.index(after: pIdx)
            }
            tIdx = tLower.index(after: tIdx)
        }

        return pIdx == pLower.endIndex
    }

    static func score(pattern: String, target: String) -> Int? {
        if pattern.isEmpty { return 0 }
        let pLower = pattern.lowercased()
        let tLower = target.lowercased()

        var pIdx = pLower.startIndex
        var tIdx = tLower.startIndex
        var score = 0
        var consecutive = 0

        if tLower.hasPrefix(pLower) {
            score += 50
        }

        while pIdx < pLower.endIndex && tIdx < tLower.endIndex {
            if pLower[pIdx] == tLower[tIdx] {
                score += 10 + (consecutive * 6)
                consecutive += 1
                pIdx = pLower.index(after: pIdx)
            } else {
                consecutive = 0
            }
            tIdx = tLower.index(after: tIdx)
        }

        return pIdx == pLower.endIndex ? score : nil
    }
}
