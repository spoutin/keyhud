import Foundation

// MARK: - AeroSpace Config Parser

struct AeroSpaceConfigParser {
    static func defaultPath() -> String {
        return XDG.aerospaceConfigPath
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
