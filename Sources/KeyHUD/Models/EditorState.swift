import SwiftUI
import AppKit

// MARK: - Settings Tab

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

// MARK: - Keybinding Editor State

class EditorState: ObservableObject {
    static let shared = EditorState()
    @Published var config: [String: [String: [[String: String]]]] = [:]
    private var savedConfig: [String: [String: [[String: String]]]] = [:]
    private var undoStack: [[String: [String: [[String: String]]]]] = []

    @Published var selectedBundleID: String = "" {
        didSet {
            autoDetectIfEmpty(for: selectedBundleID)
        }
    }
    @Published var newCategoryName: String = ""
    @Published var isAddingCategory: Bool = false
    @Published var isAddingApp: Bool = false
    @Published var newAppBundleID: String = ""
    @Published var filterOnlyConflicts: Bool = false
    @Published var isConflictDetailsExpanded: Bool = false
    @Published var recordingCategory: String? = nil
    @Published var recordingIndex: Int? = nil
    @Published var recordingVariantIndex: Int? = nil
    @Published var recordingSequence: [String] = []
    @Published var liveModifiers: String = ""

    var isRecording: Bool {
        recordingCategory != nil && recordingIndex != nil
    }

    func startRecording(category: String, index: Int, variantIndex: Int? = nil) {
        NSApp.keyWindow?.makeFirstResponder(nil)
        recordingCategory = category
        recordingIndex = index
        recordingVariantIndex = variantIndex
        recordingSequence = []
        liveModifiers = ""
    }

    func stopRecording() {
        recordingCategory = nil
        recordingIndex = nil
        recordingVariantIndex = nil
        recordingSequence = []
        liveModifiers = ""
    }

    func removeLastRecordedToken() {
        if !recordingSequence.isEmpty {
            recordingSequence.removeLast()
        }
    }

    func commitRecording() {
        guard let cat = recordingCategory, let idx = recordingIndex else { return }
        let currentTitle = config[selectedBundleID]?[cat]?[idx]["title"] ?? ""
        let currentRawKeys = config[selectedBundleID]?[cat]?[idx]["keys"] ?? ""
        var variants = currentRawKeys.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        if !recordingSequence.isEmpty {
            let combo = recordingSequence.joined()
            if let vIdx = recordingVariantIndex, vIdx < variants.count {
                variants[vIdx] = combo
            } else {
                variants.append(combo)
            }
            updateShortcut(category: cat, index: idx, title: currentTitle, keys: variants.joined(separator: " / "))
        }

        stopRecording()
    }

    func updateLiveModifiers(flags: NSEvent.ModifierFlags) {
        guard isRecording else { return }
        let clean = flags.intersection(.deviceIndependentFlagsMask)
        var s = ""
        if clean.contains(.control) { s += "⌃" }
        if clean.contains(.option) { s += "⌥" }
        if clean.contains(.shift) { s += "⇧" }
        if clean.contains(.command) { s += "⌘" }
        if liveModifiers != s {
            liveModifiers = s
        }
    }

    func handleRecordedKey(flags: NSEvent.ModifierFlags, keyCode: UInt16) -> Bool {
        guard isRecording else { return false }
        let (result, isCancel, isClear) = KeyComboDecoder.decode(flags: flags, keyCode: keyCode)

        if isCancel {
            stopRecording()
            return true
        }

        if isClear {
            removeLastRecordedToken()
            return true
        }

        if let stroke = result {
            recordingSequence.append(stroke)
            liveModifiers = ""
            return true
        }

        return false
    }

    func deleteVariant(category: String, index: Int, variantIndex: Int) {
        guard let list = config[selectedBundleID]?[category], index < list.count else { return }
        let currentTitle = list[index]["title"] ?? ""
        let currentRawKeys = list[index]["keys"] ?? ""
        var variants = currentRawKeys.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard variantIndex < variants.count else { return }
        variants.remove(at: variantIndex)
        updateShortcut(category: category, index: index, title: currentTitle, keys: variants.joined(separator: " / "))
    }

    var isDirty: Bool {
        config != savedConfig
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    func recordUndo() {
        undoStack.append(config)
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        config = prev
    }

    init() {
        reload()
    }

    func reload(selecting targetBundleID: String? = nil) {
        let loaded = CustomShortcutsManager.shared.loadConfig()
        self.config = loaded
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
        self.savedConfig = self.config
        self.undoStack.removeAll()
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
        return appDict.keys.sorted { a, b in
            if a == "Ghostty & Herdr" { return true }
            if b == "Ghostty & Herdr" { return false }
            if a == "Zsh & Shell" { return true }
            if b == "Zsh & Shell" { return false }
            if a.starts(with: "Neovim") && !b.starts(with: "Neovim") { return true }
            if !a.starts(with: "Neovim") && b.starts(with: "Neovim") { return false }
            return a < b
        }
    }

    func currentGroups() -> [ShortcutGroup] {
        guard let appDict = config[selectedBundleID] else { return [] }
        var result: [ShortcutGroup] = []
        for cat in currentCategories {
            let list = appDict[cat] ?? []
            let items = list.map { dict in
                ShortcutItem(title: dict["title"] ?? "", keys: dict["keys"] ?? "")
            }
            if !items.isEmpty {
                result.append(ShortcutGroup(title: cat, items: items))
            }
        }
        return result
    }

    func shortcuts(for category: String) -> [[String: String]] {
        return config[selectedBundleID]?[category] ?? []
    }

    func allConflictSummaries() -> [ConflictSummaryItem] {
        var results: [ConflictSummaryItem] = []
        for cat in currentCategories {
            let items = shortcuts(for: cat)
            for item in items {
                let keys = item["keys"] ?? ""
                let title = item["title"] ?? ""
                guard !keys.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
                let conflicts = ShortcutConflictDetector.shared.allConflicts(
                    for: keys,
                    currentTitle: title,
                    inCategories: currentCategories,
                    shortcutsProvider: { self.shortcuts(for: $0) }
                )
                if !conflicts.isEmpty {
                    results.append(ConflictSummaryItem(
                        category: cat,
                        title: title,
                        keys: keys,
                        conflicts: conflicts
                    ))
                }
            }
        }
        return results
    }

    func totalConflictsCount() -> Int {
        return allConflictSummaries().count
    }

    func addApp(bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recordUndo()
        if config[trimmed] == nil {
            config[trimmed] = [:]
        }
        selectedBundleID = trimmed
    }

    func addCategory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedBundleID.isEmpty else { return }
        recordUndo()
        if config[selectedBundleID] == nil {
            config[selectedBundleID] = [:]
        }
        if config[selectedBundleID]?[trimmed] == nil {
            config[selectedBundleID]?[trimmed] = [
                ["title": "New Shortcut", "keys": ""]
            ]
        }
    }

    func deleteCategory(name: String) {
        guard !selectedBundleID.isEmpty else { return }
        recordUndo()
        config[selectedBundleID]?.removeValue(forKey: name)
    }

    func addShortcut(category: String) {
        guard !selectedBundleID.isEmpty else { return }
        recordUndo()
        if config[selectedBundleID] == nil {
            config[selectedBundleID] = [:]
        }
        if config[selectedBundleID]?[category] == nil {
            config[selectedBundleID]?[category] = []
        }
        config[selectedBundleID]?[category]?.append(["title": "New Shortcut", "keys": ""])
    }

    func updateShortcut(category: String, index: Int, title: String, keys: String) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        if items[index]["title"] == title && items[index]["keys"] == keys { return }
        recordUndo()
        items[index] = ["title": title, "keys": keys]
        config[selectedBundleID]?[category] = items
    }

    func deleteShortcut(category: String, index: Int) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        recordUndo()
        items.remove(at: index)
        config[selectedBundleID]?[category] = items
    }

    func insertModifier(_ mod: String, category: String, index: Int) {
        guard !selectedBundleID.isEmpty,
              var items = config[selectedBundleID]?[category],
              index < items.count else { return }
        recordUndo()
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
    }

    func save() {
        do {
            try CustomShortcutsManager.shared.saveConfig(config)
            savedConfig = config
            undoStack.removeAll()
        } catch {
            print("Error saving shortcuts config: \(error)")
        }
    }

    func revert() {
        reload(selecting: selectedBundleID)
    }
}
