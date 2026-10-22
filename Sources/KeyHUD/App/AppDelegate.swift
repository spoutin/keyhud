import AppKit

// MARK: - App Delegate & Menu Controller

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static var shared: AppDelegate?
    var statusItem: NSStatusItem?
    var toggleMenuItem: NSMenuItem?

    var activityToken: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Prevent macOS App Nap from aggressively sleeping the background hotkey listener
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Global Hotkey Listener"
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.circle", accessibilityDescription: "KeyHUD")
        }

        let menu = NSMenu()
        menu.delegate = self

        // Header Version Pill
        let versionItem = NSMenuItem(title: "KeyHUD v\(AppInfo.version) (\(AppInfo.channelName))", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(title: "Toggle KeyHUD", action: #selector(toggleHUD), keyEquivalent: "?")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        self.toggleMenuItem = toggleItem
        menu.addItem(toggleItem)
        updateToggleMenuItemTitle()

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Keyboard Heatmap...", action: #selector(openKeyboardHeatmap), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Edit Keybindings...", action: #selector(openKeybindingEditor), keyEquivalent: "k"))
        menu.addItem(NSMenuItem(title: "Relaunch KeyHUD", action: #selector(relaunchApp), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Import Shortcuts File... (.json / .keyclu)", action: #selector(importFileAction), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Auto-Detect from Local Configs", action: #selector(autoDetectAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Shortcuts JSON...", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About KeyHUD...", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit KeyHUD", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu

        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        // Pre-warm menu bar cache when user switches apps so HUD toggle is instant
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier != Bundle.main.bundleIdentifier {
                MenuScanner.prewarm(app: app)
            }
        }
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            MenuScanner.prewarm(app: frontApp)
        }

        HotKeyManager.shared.start()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateToggleMenuItemTitle()
    }

    func updateToggleMenuItemTitle() {
        let trigger = TriggerType(rawValue: AppSettings.shared.triggerType) ?? .doubleTapAndHold
        toggleMenuItem?.title = "Toggle KeyHUD (\(trigger.shortBadge))"
    }

    @objc func toggleHUD() {
        HUDWindowController.shared.toggle()
    }

    @objc func openSettings() {
        SettingsWindowController.shared.openSettings()
    }

    @objc func openKeybindingEditor() {
        SettingsWindowController.shared.openSettings(selectingTab: .shortcuts)
    }

    @objc func relaunchApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["/Applications/KeyHUD.app"]
        try? task.run()
        NSApplication.shared.terminate(nil)
    }

    @objc func importFileAction() {
        promptImportFile()
    }

    func promptImportFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.message = "Select a KeyHUD .json or KeyClu .keyclu file to import"

        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            let res = CustomShortcutsManager.shared.importFile(from: url)
            let alert = NSAlert()
            switch res {
            case .success(let count):
                alert.messageText = "Import Successful"
                alert.informativeText = "Successfully imported \(count) shortcuts into KeyHUD!"
                alert.alertStyle = .informational
            case .failure(let err):
                alert.messageText = "Import Failed"
                alert.informativeText = err.localizedDescription
                alert.alertStyle = .warning
            }
            alert.runModal()
        }
    }

    @objc func autoDetectAction() {
        let count = CustomShortcutsManager.shared.autoDetectLocalConfigs()
        let alert = NSAlert()
        alert.messageText = "Auto-Detection Complete"
        alert.informativeText = "Successfully auto-detected and synced \(count) shortcuts from your local Herdr, Zsh, and Neovim configurations!"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func openKeyboardHeatmap() {
        SettingsWindowController.shared.openSettings(selectingTab: .shortcuts)
    }

    @objc func openAbout() {
        SettingsWindowController.shared.openSettings(selectingTab: .about)
    }

    @objc func openConfig() {
        let url = URL(fileURLWithPath: XDG.keyhudConfigFile)
        NSWorkspace.shared.open(url)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
