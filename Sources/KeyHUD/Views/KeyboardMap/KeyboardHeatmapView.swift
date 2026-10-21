import SwiftUI
import AppKit

// MARK: - Embedded Keyboard Heatmap View (inside Keybinding Editor)

struct EmbeddedKeyboardHeatmapView: View {
    @ObservedObject var state: EditorState
    let accent: Color
    @ObservedObject var settings = AppSettings.shared

    // Current app's mapped keybindings
    private var currentBindings: [MappedKeybinding] {
        var list: [MappedKeybinding] = []
        let appName = state.displayName(for: state.selectedBundleID)

        // Read active editor groups for selected app
        let groups = state.currentGroups()
        for group in groups {
            for item in group.items {
                list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: appName))
            }
        }

        // Also cross-reference AeroSpace if selected
        if state.selectedBundleID.lowercased().contains("aerospace") {
            for group in AeroSpaceConfigParser.parse() {
                for item in group.items {
                    list.append(MappedKeybinding(shortcut: item, category: group.title, appScope: "AeroSpace"))
                }
            }
        }

        return list
    }

    // Total layout conflicts for current modifier combo
    private var totalConflictsCount: Int {
        var count = 0
        for row in KeyboardLayout.standardMac75 {
            for key in row.keys {
                let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeHeatmapModifiers, bindings: currentBindings)
                if heat.isConflict {
                    count += 1
                }
            }
        }
        return count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar & Toggles
            HStack(spacing: 10) {
                // Collapse / Expand Toggle
                Button(action: {
                    state.isKeyboardHeatmapCollapsed.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: state.isKeyboardHeatmapCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accent)

                        Text("KEYBOARD HEATMAP & KEY AVAILABILITY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if totalConflictsCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                        Text("\(totalConflictsCount) Conflicts on Layout")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(8)
                }

                Spacer()

                if !state.isKeyboardHeatmapCollapsed {
                    // Active Modifier Toggles
                    HStack(spacing: 4) {
                        Text("MODIFIERS:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)

                        modifierButton(title: "⌘ Cmd", flag: .command, color: .blue)
                        modifierButton(title: "⌥ Opt", flag: .option, color: .orange)
                        modifierButton(title: "⌃ Ctrl", flag: .control, color: .purple)
                        modifierButton(title: "⇧ Shift", flag: .shift, color: .green)

                        Button("Clear") {
                            state.activeHeatmapModifiers = []
                            state.selectedHeatmapKey = nil
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)
                        .padding(.leading, 3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))

            // Expandable Keyboard Body
            if !state.isKeyboardHeatmapCollapsed {
                VStack(spacing: 8) {
                    // Keyboard Chassis
                    keyboardChassisView

                    // Selected Key Detail Inspector
                    if let key = state.selectedHeatmapKey {
                        keyInspectorCard(for: key)
                    }

                    // Legend Footer
                    legendFooterBar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.07, green: 0.08, blue: 0.09))
            }

            Divider()
        }
    }

    // MARK: - Modifier Button Component

    private func modifierButton(title: String, flag: NSEvent.ModifierFlags, color: Color) -> some View {
        let isActive = state.activeHeatmapModifiers.contains(flag)
        return Button(action: {
            if isActive {
                state.activeHeatmapModifiers.remove(flag)
            } else {
                state.activeHeatmapModifiers.insert(flag)
            }
        }) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isActive ? color : Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isActive ? color : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Keyboard Chassis View

    private var keyboardChassisView: some View {
        VStack(spacing: 3) {
            ForEach(KeyboardLayout.standardMac75) { row in
                HStack(spacing: 3) {
                    ForEach(row.keys) { key in
                        keycapView(for: key, rowId: row.id)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(red: 0.10, green: 0.11, blue: 0.13))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Single Keycap View

    private func keycapView(for key: PhysicalKey, rowId: Int) -> some View {
        let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeHeatmapModifiers, bindings: currentBindings)
        let isSelected = state.selectedHeatmapKey?.id == key.id
        let isHovered = state.hoveredHeatmapKeyId == key.id
        let isSpecialModifier = key.isModifier && isPhysicalModifierActive(key: key)

        let rowHeight: CGFloat = (rowId == 0) ? 22 : 36

        return Button(action: {
            state.selectedHeatmapKey = key
        }) {
            ZStack(alignment: .topLeading) {
                // Background Styling
                keycapBackground(heat: heat, isSelected: isSelected, isModifierActive: isSpecialModifier)

                // Keycap Labels
                VStack(alignment: .leading, spacing: 0) {
                    // Top Hardware Glyph
                    Text(key.glyph)
                        .font(.system(size: rowId == 0 ? 8 : 10, weight: .bold))
                        .foregroundColor(keycapGlyphColor(heat: heat, isModifierActive: isSpecialModifier))

                    Spacer(minLength: 0)

                    // Bottom Mapped Action Title
                    if case .assigned(let binding) = heat {
                        Text(binding.shortcut.title)
                            .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(accent)
                            .lineLimit(1)
                    } else if case .conflict = heat {
                        Text("⚠️ Conflict")
                            .font(.system(size: 6.5, weight: .bold))
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
            }
            .frame(minWidth: 18 * key.widthRatio, maxWidth: .infinity)
            .frame(height: rowHeight)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            state.hoveredHeatmapKeyId = hovering ? key.id : nil
        }
    }

    private func isPhysicalModifierActive(key: PhysicalKey) -> Bool {
        if key.id == "r5_lcmd" || key.id == "r5_rcmd" {
            return state.activeHeatmapModifiers.contains(.command)
        } else if key.id == "r5_lopt" || key.id == "r5_ropt" {
            return state.activeHeatmapModifiers.contains(.option)
        } else if key.id == "r5_lctrl" {
            return state.activeHeatmapModifiers.contains(.control)
        } else if key.id == "r4_lshift" || key.id == "r4_rshift" {
            return state.activeHeatmapModifiers.contains(.shift)
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
                return accent.opacity(0.25)
            case .available:
                return Color(red: 0.15, green: 0.16, blue: 0.19)
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
                return accent
            case .available:
                return Color.white.opacity(0.08)
            }
        }()

        RoundedRectangle(cornerRadius: 4)
            .fill(baseColor)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
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

    // MARK: - Key Inspector Card

    private func keyInspectorCard(for key: PhysicalKey) -> some View {
        let heat = KeyboardLayout.evaluateKey(key: key, activeModifiers: state.activeHeatmapModifiers, bindings: currentBindings)
        let comboString = formatModifierPrefix(state.activeHeatmapModifiers) + key.glyph.uppercased()
        let appName = state.displayName(for: state.selectedBundleID)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(comboString)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    switch heat {
                    case .assigned(let binding):
                        Text("Assigned • \(binding.category)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.14))
                            .cornerRadius(4)
                    case .conflict(let bindings):
                        Text("⚠️ \(bindings.count) Colliding Shortcuts")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(4)
                    case .available:
                        Text("Available (Free)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                }

                switch heat {
                case .assigned(let binding):
                    Text(binding.shortcut.title)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                case .conflict(let bindings):
                    HStack(spacing: 8) {
                        ForEach(bindings) { b in
                            Text("• \(b.shortcut.title) (\(b.category))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                case .available:
                    Text("No shortcut assigned to '\(comboString)' in \(appName). Available to bind!")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button("Dismiss") {
                state.selectedHeatmapKey = nil
            }
            .font(.system(size: 10))
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Legend Footer Bar

    private var legendFooterBar: some View {
        HStack(spacing: 12) {
            legendItem(color: accent, label: "Assigned")
            legendItem(color: Color.white.opacity(0.2), label: "Available (Free)")
            legendItem(color: .red, label: "Conflict / Collision")
            Spacer()
            Text("Click key to inspect • Toggle modifiers above to update layout")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .font(.system(size: 10))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
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
