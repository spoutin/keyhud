import AppKit

// MARK: - Pre-Cached Running Apps Tracker

struct RunningAppItem: Identifiable, Equatable {
    let id: pid_t
    let bundleIdentifier: String
    let localizedName: String
    let icon: NSImage

    static func == (lhs: RunningAppItem, rhs: RunningAppItem) -> Bool {
        lhs.id == rhs.id
    }
}

class RunningAppsTracker: ObservableObject {
    static let shared = RunningAppsTracker()

    @Published var runningApps: [RunningAppItem] = []

    init() {
        refresh()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceChanged),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceChanged),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    @objc private func workspaceChanged(_ notif: Notification) {
        refresh()
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let apps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
                .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
                .map { app in
                    RunningAppItem(
                        id: app.processIdentifier,
                        bundleIdentifier: app.bundleIdentifier ?? "",
                        localizedName: app.localizedName ?? "App",
                        icon: app.icon ?? NSImage()
                    )
                }
            DispatchQueue.main.async {
                self.runningApps = apps
            }
        }
    }
}
