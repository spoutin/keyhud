import SwiftUI
import AppKit

// MARK: - Native Mac Settings View

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var perm = PermissionChecker.shared
    @ObservedObject var editorState = EditorState.shared
    var onClose: () -> Void

    var selectedTab: SettingsTab {
        SettingsTab(rawValue: settings.selectedSettingsTab) ?? .general
    }

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Top Tab Navigation Bar
            HStack(spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            settings.selectedSettingsTab = tab.rawValue
                        }
                        SettingsWindowController.shared.updateSizeForTab(tab)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selectedTab == tab ? accent : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.75))

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case .general:
                    generalTabView
                case .appearance:
                    appearanceTabView
                case .shortcuts:
                    shortcutsEditorTabView
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer Actions
            HStack {
                if selectedTab == .shortcuts {
                    Text("Edits persist to \(XDG.keyhudConfigFile)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Button("Reset Defaults") {
                        settings.widthPercent = 75
                        settings.heightPercent = 65
                        settings.triggerType = 0
                        settings.holdDuration = 0.35
                        settings.accentTheme = AccentTheme.cyan.rawValue
                        settings.appearanceMode = ColorSchemeMode.dark.rawValue
                        settings.isPinned = false
                        HUDWindowController.shared.applyScreenPercentageFrame()
                    }
                }

                Spacer()

                Button("Done") {
                    if editorState.isDirty {
                        editorState.save()
                    }
                    HUDWindowController.shared.applyScreenPercentageFrame()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .frame(minWidth: 700, minHeight: 560)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            perm.refresh()
        }
    }

    // MARK: - General Tab View
    private var generalTabView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // System Permissions Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("SYSTEM PERMISSIONS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        if perm.isAccessibilityGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Accessibility Access")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Granted")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.16))
                                        .cornerRadius(4)
                                }
                                Text("KeyHUD is authorized to auto-detect shortcuts from Chrome, Safari, and other Mac apps, and execute click actions.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Check Status") {
                                perm.refresh()
                            }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Accessibility Access")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Permission Required")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.16))
                                        .cornerRadius(4)
                                }
                                Text("If already toggled ON in System Settings, click Relaunch KeyHUD below so macOS applies the permission token.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Button("Relaunch KeyHUD") {
                                    AppDelegate.shared?.relaunchApp()
                                }

                                Button("Open Settings") {
                                    HUDWindowController.shared.hide()
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(perm.isAccessibilityGranted ? Color.green.opacity(0.08) : Color.orange.opacity(0.12))
                    .cornerRadius(8)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Activation Trigger & Behavior Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACTIVATION TRIGGER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(TriggerType.allCases) { type in
                            Button(action: {
                                settings.triggerType = type.rawValue
                            }) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: settings.triggerType == type.rawValue ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(settings.triggerType == type.rawValue ? settings.currentAccentColor : .secondary)
                                        .font(.system(size: 14))
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.title)
                                            .font(.system(size: 13, weight: settings.triggerType == type.rawValue ? .semibold : .regular))
                                            .foregroundColor(.primary)
                                        Text(type.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    if settings.triggerType == TriggerType.singleHold.rawValue || settings.triggerType == TriggerType.doubleTapAndHold.rawValue {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Command Hold Delay")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int(settings.holdDuration * 1000)) ms")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(settings.currentAccentColor)
                            }
                            Slider(value: $settings.holdDuration, in: 0.15...0.80, step: 0.05)
                        }
                        .padding(.top, 4)
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // Launch at Login Toggle
                    Button(action: {
                        settings.launchAtLogin.toggle()
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.launchAtLogin ? "checkmark.square.fill" : "square")
                                .foregroundColor(settings.launchAtLogin ? settings.currentAccentColor : .secondary)
                                .font(.system(size: 15))
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at Login (Start on Boot)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Automatically start KeyHUD in the background when logging into your Mac.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .padding(.vertical, 2)

                    // Persistent Pin Toggle
                    Button(action: {
                        settings.isPinned.toggle()
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.isPinned ? "checkmark.square.fill" : "square")
                                .foregroundColor(settings.isPinned ? settings.currentAccentColor : .secondary)
                                .font(.system(size: 15))
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Persistent Pin Mode")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Keep the HUD floating on screen even after running shortcuts, ideal for multi-monitor setups or rapid reference.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("Global shortcut ⌘⇧/ (Cmd+Shift+/) also activates KeyHUD at any time.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Search Scope Preferences Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEFAULT SEARCH SCOPE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(SearchScope.allCases) { scope in
                            Button(action: {
                                settings.defaultSearchScope = scope.rawValue
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: settings.defaultSearchScope == scope.rawValue ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(settings.defaultSearchScope == scope.rawValue ? settings.currentAccentColor : .secondary)
                                        .font(.system(size: 13))
                                    Image(systemName: scope.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(scope.rawValue)
                                        .font(.system(size: 13, weight: settings.defaultSearchScope == scope.rawValue ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Text("Determines what categories are queried when typing in the HUD search bar. Can also be toggled on the fly in the HUD.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Command Palette Mode Preferences Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("COMMAND PALETTE MODE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(CommandPaletteMode.allCases) { mode in
                            Button(action: {
                                settings.commandPaletteMode = mode.rawValue
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: settings.commandPaletteMode == mode.rawValue ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(settings.commandPaletteMode == mode.rawValue ? settings.currentAccentColor : .secondary)
                                        .font(.system(size: 13))
                                        .padding(.top, 1)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.rawValue)
                                            .font(.system(size: 13, weight: settings.commandPaletteMode == mode.rawValue ? .semibold : .regular))
                                            .foregroundColor(.primary)
                                        Text(mode.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Text("Indexes all clickable menu bar items, allowing execution even for actions without shortcuts (Paletro-style).")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(18)
        }
    }

    // MARK: - Appearance Tab View
    private var appearanceTabView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Color Scheme Mode Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("APPEARANCE THEME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(ColorSchemeMode.allCases) { mode in
                            Button(action: {
                                settings.appearanceMode = mode.rawValue
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: mode == .automatic ? "circle.righthalf.filled" : (mode == .light ? "sun.max.fill" : "moon.fill"))
                                        .font(.system(size: 13))
                                    Text(mode.rawValue)
                                        .font(.system(size: 13, weight: settings.appearanceMode == mode.rawValue ? .semibold : .regular))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundColor(settings.appearanceMode == mode.rawValue ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(settings.appearanceMode == mode.rawValue ? settings.currentAccentColor : Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Accent Theme Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACCENT THEME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button(action: {
                                settings.accentTheme = theme.rawValue
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 26, height: 26)
                                        if settings.accentTheme == theme.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    Text(theme.rawValue)
                                        .font(.system(size: 11, weight: settings.accentTheme == theme.rawValue ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(settings.accentTheme == theme.rawValue ? theme.color.opacity(0.18) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Row Contrast & Scanning (Zebra Striping)
                VStack(alignment: .leading, spacing: 10) {
                    Text("ROW CONTRAST & SCANNING")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Toggle(isOn: $settings.zebraStriping) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Zebra Striping")
                                .font(.system(size: 13, weight: .medium))
                            Text("Alternates row shading across columns for easier horizontal scanning.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: settings.currentAccentColor))
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Window Sizing Section (Moved to Appearance)
                VStack(alignment: .leading, spacing: 10) {
                    Text("MAXIMUM WINDOW SIZE CEILING")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max Horizontal Width (% of screen)")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(settings.widthPercent))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(settings.currentAccentColor)
                        }
                        Slider(value: $settings.widthPercent, in: 25...100, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max Vertical Height (% of screen)")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(settings.heightPercent))%")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(settings.currentAccentColor)
                        }
                        Slider(value: $settings.heightPercent, in: 25...100, step: 1)
                    }

                    Text("The HUD automatically shrinks to fit smaller shortcut lists, using these percentages as the maximum ceiling.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(18)
        }
    }

    // MARK: - Shortcuts & Editor Tab View
    private var shortcutsEditorTabView: some View {
        VStack(spacing: 0) {
            // Quick Tools Bar
            HStack(spacing: 12) {
                Button("Open JSON Config...") {
                    AppDelegate.shared?.openConfig()
                }

                Button("Import File (.json / .keyclu)...") {
                    AppDelegate.shared?.promptImportFile()
                }

                Button("Auto-Detect Configs") {
                    AppDelegate.shared?.autoDetectAction()
                }

                Spacer()

                if editorState.isDirty {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Unsaved Changes")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Embedded Keybinding Editor
            KeybindingEditorView(state: editorState) {
                // In-tab dismiss handler
            }
        }
    }
}

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var isHandlingClosePrompt = false
    private var eventMonitor: Any?

    init() {
        let initialTab = SettingsTab(rawValue: AppSettings.shared.selectedSettingsTab) ?? .general
        let initialSize: NSSize
        switch initialTab {
        case .general: initialSize = NSSize(width: 760, height: 600)
        case .appearance: initialSize = NSSize(width: 760, height: 600)
        case .shortcuts: initialSize = NSSize(width: 880, height: 680)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyHUD Settings & Keybinding Editor"
        window.collectionBehavior = [.moveToActiveSpace]
        window.minSize = NSSize(width: 700, height: 500)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)

        window.delegate = self

        let view = SettingsView { [weak self] in
            self?.window?.performClose(nil)
        }
        window.contentView = NSHostingView(rootView: view)

        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self, let win = self.window, win.isKeyWindow else { return event }
            if EditorState.shared.isRecording {
                EditorState.shared.updateLiveModifiers(flags: event.modifierFlags)
            }
            return event
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let win = self.window, win.isKeyWindow else { return event }

            // If editor is currently recording a shortcut, intercept and decode keystroke!
            if EditorState.shared.isRecording {
                _ = EditorState.shared.handleRecordedKey(flags: event.modifierFlags, keyCode: event.keyCode)
                return nil // Always swallow keystrokes completely during recording!
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .command && event.keyCode == 13 { // '⌘W'
                // Check if user is actively focused on an editable text input (field editor)
                if let responder = win.firstResponder, responder is NSTextView {
                    // Do not close; allow field editing / shortcut typing
                    return event
                }

                // Not editing a text field -> perform close with dirty protection
                win.performClose(nil)
                return nil
            }
            return event
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if !EditorState.shared.isDirty {
            return true
        }

        if isHandlingClosePrompt {
            return false
        }

        isHandlingClosePrompt = true
        let alert = NSAlert()
        alert.messageText = "Do you want to save your changes before closing?"
        alert.informativeText = "Your keybinding modifications will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")

        alert.beginSheetModal(for: sender) { [weak self, weak sender] response in
            self?.isHandlingClosePrompt = false
            switch response {
            case .alertFirstButtonReturn: // Save
                EditorState.shared.save()
                sender?.close()
            case .alertThirdButtonReturn: // Don't Save
                EditorState.shared.revert()
                sender?.close()
            default: // Cancel
                break
            }
        }

        return false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSizeForTab(_ tab: SettingsTab) {
        guard let window = window else { return }
        let targetSize: NSSize
        switch tab {
        case .general:
            targetSize = NSSize(width: 760, height: 600)
        case .appearance:
            targetSize = NSSize(width: 760, height: 600)
        case .shortcuts:
            targetSize = NSSize(width: 880, height: 680)
        }

        if abs(window.frame.width - targetSize.width) > 2 || abs(window.frame.height - targetSize.height) > 2 {
            var frame = window.frame
            let oldHeight = frame.size.height
            frame.origin.y += (oldHeight - targetSize.height)
            frame.size = targetSize
            window.setFrame(frame, display: true, animate: false)
        }
    }

    func openSettings(selectingTab: SettingsTab = .general, bundleID: String? = nil) {
        AppSettings.shared.selectedSettingsTab = selectingTab.rawValue
        EditorState.shared.reload(selecting: bundleID)
        AppSettings.shared.updateWindowsAppearance()
        updateSizeForTab(selectingTab)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
