import Foundation

// MARK: - App Information & Metadata

struct AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1-beta.9"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var isBeta: Bool {
        version.contains("-beta") || version.contains("-alpha") || version.contains("-rc")
    }

    static var channelName: String {
        isBeta ? "Beta Channel" : "Stable Channel"
    }

    static let publisher = "@spoutin"
    static let githubURL = URL(string: "https://github.com/spoutin/keyhud")!
    static let issuesURL = URL(string: "https://github.com/spoutin/keyhud/issues")!
    static let tapURL = URL(string: "https://github.com/spoutin/homebrew-tap")!
    static let license = "MIT License"
}
