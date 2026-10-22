import Foundation

// MARK: - In-App Release Notes Models

struct ReleaseNoteSection: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let items: [String]
}

struct ReleaseNotes {
    static let currentVersion = "1.0.1"
    static let releaseDate = "October 2026"
    static let headline = "KeyHUD 1.0.1 General Release"
    static let summary = "This milestone general release delivers physical keyboard heatmaps, OS daemon vs AppKit conflict isolation, instant zero-latency HUD presentation, and rock-solid modifier triple-tap activation."

    static let sections: [ReleaseNoteSection] = [
        ReleaseNoteSection(
            category: "Core Responsiveness & Reliability",
            icon: "bolt.fill",
            items: [
                "Triple-Tap Modifier Trigger: Fixed a critical issue where regular typing swallowed the first Command tap, requiring an unintended 4th tap (quad-tap).",
                "Instant HUD Presentation: Eliminated the ~2-second opening delay by pre-warming frontmost application menus on app switch and performing menu tree walking asynchronously.",
                "Zero Sleep Wake Latency: Registered latency-critical activity assertion to prevent macOS App Nap from delaying global hotkey listeners.",
                "Multi-Modifier Combo Protection: Cleanly resets tap accumulation when pressing combination shortcuts (Cmd+C, Cmd+Tab, Cmd+Shift)."
            ]
        ),
        ReleaseNoteSection(
            category: "Physical Keyboard Heatmap",
            icon: "keyboard.fill",
            items: [
                "Interactive ANSI Key Matrix: Realistic physical keyboard visualization showing occupied hotkeys and density heatmaps.",
                "Live Modifier Toggles: Switch between ⌘, ⌥, ⌃, and ⇧ to view modifier layers in real-time.",
                "Visual Conflict Indicators: Highlighting conflicting keys directly on the physical keyboard matrix."
            ]
        ),
        ReleaseNoteSection(
            category: "Intelligent Conflict Detection",
            icon: "exclamationmark.triangle.fill",
            items: [
                "Daemon vs Convention Isolation: Separated true OS daemon intercepts from standard macOS AppKit shortcuts (⌘H, ⌘Q, ⌘W, ⌘M).",
                "Semantic Intent Badges: Conforming standard shortcuts now display an Apple badge without triggering false collision warnings.",
                "TUI & Terminal Domain Isolation: Terminal tools and window managers are properly scoped so background shell keys don't falsely collide."
            ]
        ),
        ReleaseNoteSection(
            category: "Settings & Keybinding Editor",
            icon: "slider.horizontal.3",
            items: [
                "Fixed False 'Unsaved Changes': Editor baseline synchronization eliminates unwarranted dirty state flags when inspecting or switching applications.",
                "Frozen 4-Tab Settings: Stable, fixed-dimension tabs (General, Appearance, Shortcuts & Editor, About) with no layout jumping.",
                "In-App Release Notes: Automatic 'What's New' announcement after updates and direct changelog viewer in the About tab."
            ]
        )
    ]
}
