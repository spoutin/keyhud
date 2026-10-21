import SwiftUI
import AppKit

// MARK: - Keyboard Heatmap State

class KeyboardHeatmapState: ObservableObject {
    static let shared = KeyboardHeatmapState()

    @Published var selectedScope: String = "ghostty"
    @Published var activeModifiers: NSEvent.ModifierFlags = [.command]
    @Published var selectedKey: PhysicalKey? = nil
    @Published var hoveredKeyId: String? = nil
}

// MARK: - Keyboard Heatmap View

struct KeyboardHeatmapView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var state = KeyboardHeatmapState.shared

    // Available Scopes
    private var scopeOptions: [(id: String, name: String)] {
        var options: [(id: String, name: String)] = [
            ("ghostty", "Ghostty (Terminal)"),
            ("aerospace", "AeroSpace (Global Tiling)"),
            ("macos", "macOS System"),
            ("all", "All Combined (Cross-Layer Collisions)")
        ]

        // Add frontmost app if available and not Ghostty
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontmost.bundleIdentifier,
           bundleId != "com.mitchellh.ghostty" && bundleId != "com.ablack.KeyHUD" {
            options.insert((bundleId, "\(frontmost.localizedName ?? "Active App") (Frontmost)"), at: 0)
        }

        return options
    }

    // Computed bindings for current scope
    private var currentBindings: [MappedKeybinding] {
        var list: [MappedKeybinding] = []

        if state.selectedScope == "ghostty" {
            if let groups = CustomShortcutsManager.shared.groups(for: "com.mitchellh.ghostty") {
                for group in groups {
                    for item in group.items {
                        list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "Ghostty"))
                    }
                }
            }
        } else if state.selectedScope == "aerospace" {
            let groups = AeroSpaceConfigParser.parse()
            for group in groups {
                for item in group.items {
                    list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "AeroSpace"))
                }
            }
        } else if state.selectedScope == "macos" {
            let groups = MacOSGlobalShortcuts.getGroups()
            for group in groups {
                for item in group.items {
                    list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "macOS"))
                }
            }
        } else if state.selectedScope == "all" {
            if let groups = CustomShortcutsManager.shared.groups(for: "com.mitchellh.ghostty") {
                for group in groups {
                    for item in group.items {
                        list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "Ghostty"))
                    }
                }
            }
            for group in AeroSpaceConfigParser.parse() {
                for item in group.items {
                    list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "AeroSpace"))
                }
            }
            for group in MacOSGlobalShortcuts.getGroups() {
                for item in group.items {
                    list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "macOS"))
                }
            }
        } else {
            // Other custom app bundle ID
            if let groups = CustomShortcutsManager.shared.groups(for: state.selectedScope) {
                for group in groups {
                    for item in group.items {
                        list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: state.selectedScope))
                    }
                }
            }
        }

        return list
    }

    // Total conflicts in current scope & modifier set
    private var totalConflictsCount: Int {
        var count = 0
        for row in KeyboardLayout.standardMac75 {
            for key in row.keys {
                let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeModifiers, bindings: currentBindings)
                if heat.isConflict {
                    count += 1
                }
            }
        }
        return count
    }

    var body: some View {
        VStack(spacing: 14) {
            // Top Controls Bar
            headerControlsBar

            // Keyboard Chassis
            keyboardChassisView

            // Key Detail Inspector
            if let key = state.selectedKey {
                keyInspectorCard(for: key)
            } else {
                idleInspectorCard
            }

            // Legend Footer
            legendFooterBar
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header Controls Bar

    private var headerControlsBar: some View {
        HStack(spacing: 12) {
            // Scope Picker
            HStack(spacing: 6) {
                Text("SCOPE:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                Picker("", selection: $state.selectedScope) {
                    ForEach(scopeOptions, id: \.id) { opt in
                        Text(opt.name).tag(opt.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 220)
            }

            // Conflict Warning Pill
            if totalConflictsCount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("\(totalConflictsCount) Conflicts Detected")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.red.opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.25), lineWidth: 1))
            }

            Spacer()

            // Active Modifier Buttons
            HStack(spacing: 5) {
                Text("MODIFIERS:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                modifierButton(title: "⌘ Cmd", flag: .command, color: .blue)
                modifierButton(title: "⌥ Opt", flag: .option, color: .orange)
                modifierButton(title: "⌃ Ctrl", flag: .control, color: .purple)
                modifierButton(title: "⇧ Shift", flag: .shift, color: .green)

                Button("Clear") {
                    state.activeModifiers = []
                    state.selectedKey = nil
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
    }

    private func modifierButton(title: String, flag: NSEvent.ModifierFlags, color: Color) -> some View {
        let isActive = state.activeModifiers.contains(flag)
        return Button(action: {
            if isActive {
                state.activeModifiers.remove(flag)
            } else {
                state.activeModifiers.insert(flag)
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(isActive ? color : Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isActive ? color : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Keyboard Chassis View

    private var keyboardChassisView: some View {
        VStack(spacing: 4) {
            ForEach(KeyboardLayout.standardMac75) { row in
                HStack(spacing: 4) {
                    ForEach(row.keys) { key in
                        keycapView(for: key, rowId: row.id)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }

    // MARK: - Single Keycap View

    private func keycapView(for key: PhysicalKey, rowId: Int) -> some View {
        let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeModifiers, bindings: currentBindings)
        let isSelected = state.selectedKey?.id == key.id
        let isHovered = state.hoveredKeyId == key.id
        let isSpecialModifier = key.isModifier && isPhysicalModifierActive(key: key)

        let rowHeight: CGFloat = (rowId == 0) ? 26 : 42

        return Button(action: {
            state.selectedKey = key
        }) {
            ZStack(alignment: .topLeading) {
                // Background Styling
                keycapBackground(heat: heat, isSelected: isSelected, isModifierActive: isSpecialModifier)

                // Keycap Labels
                VStack(alignment: .leading, spacing: 1) {
                    // Top Hardware Glyph
                    Text(key.glyph)
                        .font(.system(size: rowId == 0 ? 9 : 11, weight: .bold))
                        .foregroundColor(keycapGlyphColor(heat: heat, isModifierActive: isSpecialModifier))

                    Spacer(minLength: 0)

                    // Bottom Mapped Action Title
                    if case .assigned(let binding) = heat {
                        Text(binding.shortcut.title)
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundColor(settings.currentAccentColor)
                            .lineLimit(1)
                    } else if case .conflict = heat {
                        Text("⚠️ Conflict")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
            }
            .frame(minWidth: 20 * key.widthRatio, maxWidth: .infinity)
            .frame(height: rowHeight)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            state.hoveredKeyId = hovering ? key.id : nil
        }
    }

    private func isPhysicalModifierActive(key: PhysicalKey) -> Bool {
        if key.id == "r5_lcmd" || key.id == "r5_rcmd" {
            return state.activeModifiers.contains(.command)
        } else if key.id == "r5_lopt" || key.id == "r5_ropt" {
            return state.activeModifiers.contains(.option)
        } else if key.id == "r5_lctrl" {
            return state.activeModifiers.contains(.control)
        } else if key.id == "r4_lshift" || key.id == "r4_rshift" {
            return state.activeModifiers.contains(.shift)
        }
        return false
    }

    @ViewBuilder
    private func keycapBackground(heat: KeyHeatState, isSelected: Bool, isModifierActive: Bool) -> some View {
        let baseColor: Color = {
            if isModifierActive {
                return Color.blue.opacity(0.35)
            }
            switch heat {
            case .conflict:
                return Color(red: 0.35, green: 0.08, blue: 0.08)
            case .assigned:
                return settings.currentAccentColor.opacity(0.25)
            case .available:
                return Color(red: 0.14, green: 0.15, blue: 0.18)
            }
        }()

        let borderColor: Color = {
            if isSelected {
                return Color.white
            }
            if isModifierActive {
                return Color.blue
            }
            switch heat {
            case .conflict:
                return Color.red
            case .assigned:
                return settings.currentAccentColor
            case .available:
                return Color.white.opacity(0.08)
            }
        }()

        RoundedRectangle(cornerRadius: 5)
            .fill(baseColor)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 2)
    }

    private func keycapGlyphColor(heat: KeyHeatState, isModifierActive: Bool) -> Color {
        if isModifierActive {
            return .white
        }
        switch heat {
        case .conflict:
            return Color(red: 1.0, green: 0.8, blue: 0.8)
        case .assigned:
            return .white
        case .available:
            return Color(red: 0.85, green: 0.88, blue: 0.92)
        }
    }

    // MARK: - Key Inspector Cards

    private func keyInspectorCard(for key: PhysicalKey) -> some View {
        let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeModifiers, bindings: currentBindings)
        let comboString = formatModifierPrefix(state.activeModifiers) + key.glyph.uppercased()

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(comboString)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    switch heat {
                    case .assigned(let binding):
                        Text("Assigned • \(binding.appScope)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(settings.currentAccentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(settings.currentAccentColor.opacity(0.14))
                            .cornerRadius(4)
                    case .conflict(let bindings):
                        Text("⚠️ \(bindings.count) Colliding Shortcuts")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(4)
                    case .available:
                        Text("Available (Free)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                }

                switch heat {
                case .assigned(let binding):
                    Text("\(binding.shortcut.title) (\(binding.category))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                case .conflict(let bindings):
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(bindings) { b in
                            Text("• [\(b.appScope)] \(b.shortcut.title) (\(b.category))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                case .available:
                    Text("No shortcuts assigned to this key combo in the current scope.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button("Deselect") {
                state.selectedKey = nil
            }
            .font(.system(size: 11))
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var idleInspectorCard: some View {
        HStack {
            Text("Click any keycap to inspect command details, collisions, and categories.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - Legend Footer Bar

    private var legendFooterBar: some View {
        HStack(spacing: 16) {
            legendItem(color: settings.currentAccentColor, label: "Assigned")
            legendItem(color: Color.white.opacity(0.2), label: "Available (Free)")
            legendItem(color: .red, label: "Conflict / Collision")
            Spacer()
            Text("Pro tip: Toggle modifiers above to reveal occupied keymaps")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .font(.system(size: 11))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    private func formatModifierPrefix(_ flags: NSEvent.ModifierFlags) -> String {
        var str = ""
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        return str
    }
}
