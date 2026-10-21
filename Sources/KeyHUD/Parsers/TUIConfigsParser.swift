import Foundation

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
