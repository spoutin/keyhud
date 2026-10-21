import Foundation
import AppKit

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
