import Foundation
import AppKit

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
        configPath = XDG.keyhudConfigFile
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

        let sortedTitles = appConfig.keys.sorted { a, b in
            if a == "Ghostty & Herdr" { return true }
            if b == "Ghostty & Herdr" { return false }
            if a == "Zsh & Shell" { return true }
            if b == "Zsh & Shell" { return false }
            if a.starts(with: "Neovim") && !b.starts(with: "Neovim") { return true }
            if !a.starts(with: "Neovim") && b.starts(with: "Neovim") { return false }
            return a < b
        }

        var result: [ShortcutGroup] = []
        for groupTitle in sortedTitles {
            guard let itemsList = appConfig[groupTitle] else { continue }
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
        var detectedCount = 0
        var ghosttyConfig = loadConfig()["com.mitchellh.ghostty"] ?? [:]

        // 1. Scan Herdr config
        let herdrConfigPath = XDG.herdrConfigPath
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
        let nvimKeymapsPath = XDG.nvimKeymapsPath
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

        // 4. K9s, Lazygit, Atuin, VisiData TUI detection
        let k9sConfigPath = XDG.k9sConfigDir
        if FileManager.default.fileExists(atPath: k9sConfigPath) && ghosttyConfig["K9s: Kubernetes"] == nil {
            ghosttyConfig["K9s: Kubernetes"] = [
                ["title": "Pods View", "keys": ":pods"],
                ["title": "Deployments View", "keys": ":deploy"],
                ["title": "Services View", "keys": ":svc"],
                ["title": "Switch Namespaces", "keys": ":ns"],
                ["title": "Switch Contexts", "keys": ":ctx"],
                ["title": "Filter Resources", "keys": "/"],
                ["title": "Clear Filter / Back", "keys": "Esc"],
                ["title": "Describe Resource", "keys": "d"],
                ["title": "View Pod Logs", "keys": "l"],
                ["title": "Shell Exec into Pod", "keys": "s"],
                ["title": "Edit Resource YAML", "keys": "e"],
                ["title": "Toggle Wrap Logs", "keys": "w"],
                ["title": "Delete Resource", "keys": "⌃D"]
            ]
            detectedCount += 13
        }

        let lazygitConfigPath = XDG.lazygitConfigDir
        if FileManager.default.fileExists(atPath: lazygitConfigPath) && ghosttyConfig["Lazygit: Git TUI"] == nil {
            ghosttyConfig["Lazygit: Git TUI"] = [
                ["title": "Status Panel", "keys": "1"],
                ["title": "Files Panel", "keys": "2"],
                ["title": "Branches Panel", "keys": "3"],
                ["title": "Commits Panel", "keys": "4"],
                ["title": "Stash Panel", "keys": "5"],
                ["title": "Previous / Next Tab", "keys": "[ / ]"],
                ["title": "Stage / Toggle File or Hunk", "keys": "Space"],
                ["title": "Commit Changes", "keys": "c"],
                ["title": "Amend Commit", "keys": "A"],
                ["title": "Push to Remote", "keys": "P"],
                ["title": "Pull from Remote", "keys": "p"],
                ["title": "Branch Menu / Checkout", "keys": "b"],
                ["title": "Undo Action", "keys": "z"]
            ]
            detectedCount += 13
        }

        let atuinConfigPath = XDG.atuinConfigDir
        if FileManager.default.fileExists(atPath: atuinConfigPath) && ghosttyConfig["Atuin: Shell History"] == nil {
            ghosttyConfig["Atuin: Shell History"] = [
                ["title": "Interactive History Search", "keys": "⌃R"],
                ["title": "Edit Search Query", "keys": "⌃E"],
                ["title": "Inspect Command Details", "keys": "Tab"],
                ["title": "Execute Command Immediately", "keys": "⌃O"],
                ["title": "Previous / Next Result", "keys": "⌃P / ⌃N"],
                ["title": "Filter: Global / Host / Session / Dir", "keys": "⌥1 .. ⌥4"]
            ]
            detectedCount += 6
        }

        var fullConfig = loadConfig()
        fullConfig["com.mitchellh.ghostty"] = ghosttyConfig

        // 5. Auto-detect from all running regular Mac apps (Chrome, Safari, Slack, Obsidian, Finder, etc.)
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
