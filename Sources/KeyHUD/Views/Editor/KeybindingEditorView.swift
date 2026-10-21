import SwiftUI
import AppKit

// MARK: - Keybinding Editor View & Window Controller

struct KeybindingEditorView: View {
    @ObservedObject var state: EditorState
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var hiddenManager = HiddenItemsManager.shared
    var onClose: () -> Void

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                // App Selector Pill
                HStack(spacing: 8) {
                    Text("Target App:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Picker("", selection: $state.selectedBundleID) {
                        ForEach(state.availableApps, id: \.self) { app in
                            Text(state.displayName(for: app)).tag(app)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(minWidth: 200)

                    Button(action: {
                        state.recordUndo()
                        state.autoDetectFromRunningApp(bundleID: state.selectedBundleID)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Re-detect shortcuts from running application's menu bar")

                    Button(action: {
                        state.isAddingApp.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add new application by bundle identifier")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: {
                        let groups = state.currentGroups()
                        let appTitle = state.displayName(for: state.selectedBundleID)
                        let menu = NSMenu(title: "Export")
                        menu.addItem(BlockMenuItem(title: "Copy Markdown to Clipboard", iconName: "doc.on.clipboard") {
                            MarkdownExporter.copyToClipboard(appName: appTitle, groups: groups)
                        })
                        menu.addItem(BlockMenuItem(title: "Save to Documents (KeyHUD)", iconName: "folder") {
                            _ = MarkdownExporter.saveToFile(appName: appTitle, groups: groups, destination: .documents)
                        })
                        menu.addItem(BlockMenuItem(title: "Save to XDG Data (\(XDG.dataHome)/keyhud)", iconName: "shippingbox") {
                            _ = MarkdownExporter.saveToFile(appName: appTitle, groups: groups, destination: .xdgData)
                        })
                        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export...")
                        }
                    }
                    .help("Export currently configured shortcuts to Markdown")

                    // Conflict Filter Toggle Button
                    let conflictCount = state.totalConflictsCount()
                    if conflictCount > 0 {
                        Button(action: {
                            state.filterOnlyConflicts.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: state.filterOnlyConflicts ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Conflicts (\(conflictCount))")
                                    .font(.system(size: 11, weight: state.filterOnlyConflicts ? .bold : .medium))
                            }
                            .foregroundColor(state.filterOnlyConflicts ? .black : Color.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(state.filterOnlyConflicts ? Color.orange : Color.orange.opacity(0.14))
                            .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(state.filterOnlyConflicts ? "Showing conflicting shortcuts only — click to view all" : "Filter to \(conflictCount) conflicting shortcuts")
                    }

                    Button(action: {
                        state.undo()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                    }
                    .disabled(!state.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                    .help("Undo last edit (⌘Z)")

                    Button("Revert") {
                        state.revert()
                    }
                    .disabled(!state.isDirty)

                    Button("Save Changes") {
                        state.save()
                    }
                    .disabled(!state.isDirty)
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Conflict Summary Banner
            ConflictSummaryBannerView(state: state, accent: accent)

            // Inline App Adder Banner
            if state.isAddingApp {
                HStack(spacing: 10) {
                    Text("New Bundle ID:")
                        .font(.system(size: 12, weight: .semibold))
                    TextField("e.g. com.apple.Safari or global", text: $state.newAppBundleID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 250)

                    Button("Add App") {
                        if !state.newAppBundleID.isEmpty {
                            state.addApp(bundleID: state.newAppBundleID)
                            state.newAppBundleID = ""
                            state.isAddingApp = false
                        }
                    }
                    Button("Cancel") {
                        state.newAppBundleID = ""
                        state.isAddingApp = false
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(accent.opacity(0.12))

                Divider()
            }

            // Categories & Shortcuts Scroll View
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Category adder banner
                    HStack {
                        if state.isAddingCategory {
                            HStack(spacing: 8) {
                                TextField("Category Name (e.g. Navigation & Tabs)", text: $state.newCategoryName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 240)

                                Button("Add") {
                                    if !state.newCategoryName.isEmpty {
                                        state.addCategory(name: state.newCategoryName)
                                        state.newCategoryName = ""
                                        state.isAddingCategory = false
                                    }
                                }
                                Button("Cancel") {
                                    state.newCategoryName = ""
                                    state.isAddingCategory = false
                                }
                            }
                        } else {
                            Button(action: { state.isAddingCategory = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.rectangle")
                                    Text("Add Category")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(accent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()
                    }
                    .padding(.top, 4)

                    if state.currentCategories.isEmpty {
                        if !AXIsProcessTrusted() {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)
                                Text("Accessibility Permission Required")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("macOS requires Accessibility access for KeyHUD to auto-detect menus for \(state.displayName(for: state.selectedBundleID)).\n\nPlease toggle KeyHUD ON in System Settings → Privacy & Security → Accessibility.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 420)
                                Button("Open Privacy & Security Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                Text("No shortcut categories configured for \(state.selectedBundleID).")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("Click '+ Add Category' above to create custom shortcuts.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    } else {
                        ForEach(state.currentCategories, id: \.self) { category in
                            let allCategoryItems = state.shortcuts(for: category)
                            let visibleCategoryItems: [(Int, [String: String])] = allCategoryItems.enumerated().compactMap { idx, item in
                                if !state.filterOnlyConflicts { return (idx, item) }
                                let k = item["keys"] ?? ""
                                let t = item["title"] ?? ""
                                guard !k.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
                                let confs = ShortcutConflictDetector.shared.allConflicts(
                                    for: k,
                                    currentTitle: t,
                                    inCategories: state.currentCategories,
                                    shortcutsProvider: { state.shortcuts(for: $0) }
                                )
                                return confs.isEmpty ? nil : (idx, item)
                            }

                            if !state.filterOnlyConflicts || !visibleCategoryItems.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Category Header
                                    HStack(spacing: 10) {
                                        Text(category.uppercased())
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(accent)

                                        if state.selectedBundleID == "com.mitchellh.ghostty" {
                                            let isShownOnMain = settings.isGhosttyCategoryShownOnMain(category)
                                            Button(action: {
                                                settings.toggleGhosttyCategoryOnMain(category)
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: isShownOnMain ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(isShownOnMain ? Color.green : .secondary)
                                                        .font(.system(size: 11))
                                                    Text(isShownOnMain ? "Shown on Main" : "Sub-menu Only")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(isShownOnMain ? .primary : .secondary)
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(isShownOnMain ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .help("Toggle whether this category appears on Ghostty's main combined cheatsheet")
                                        }

                                        if hiddenManager.isCategoryHidden(bundleID: state.selectedBundleID, category: category) {
                                            Text("HIDDEN IN HUD")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.15))
                                                .cornerRadius(4)
                                        }

                                        Spacer()

                                        // Hide / Unhide Category from HUD Button
                                        let isCatHidden = hiddenManager.isCategoryHidden(bundleID: state.selectedBundleID, category: category)
                                        Button(action: {
                                            hiddenManager.toggleCategoryHidden(bundleID: state.selectedBundleID, category: category)
                                        }) {
                                            Image(systemName: isCatHidden ? "eye.slash.fill" : "eye")
                                                .font(.system(size: 11))
                                                .foregroundColor(isCatHidden ? Color.orange : Color.secondary)
                                                .padding(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help(isCatHidden ? "Unhide this category in HUD" : "Hide this entire category/column from HUD")

                                        Button(action: {
                                            state.deleteCategory(name: category)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .padding(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Delete Category")
                                    }

                                    Divider()

                                    // Shortcuts List
                                    ForEach(visibleCategoryItems, id: \.0) { index, item in
                                    let currentTitle = item["title"] ?? ""
                                    let currentKeys = item["keys"] ?? ""

                                    HStack(spacing: 10) {
                                        TextField("Title", text: Binding(
                                            get: { currentTitle },
                                            set: { state.updateShortcut(category: category, index: index, title: $0, keys: currentKeys) }
                                        ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)

                                        let variants = currentKeys.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

                                        HStack(spacing: 6) {
                                            if variants.isEmpty {
                                                let isRecordingThisEmpty = (state.recordingCategory == category && state.recordingIndex == index)
                                                if isRecordingThisEmpty {
                                                    RecordingBadgeView(state: state)
                                                } else {
                                                    Button(action: {
                                                        state.startRecording(category: category, index: index, variantIndex: 0)
                                                    }) {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "record.circle")
                                                                .font(.system(size: 12, weight: .semibold))
                                                                .foregroundColor(accent)
                                                            Text("Record Shortcut")
                                                                .font(.system(size: 11, weight: .semibold))
                                                                .foregroundColor(accent)
                                                        }
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(accent.opacity(0.12))
                                                        .cornerRadius(6)
                                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.35), lineWidth: 1))
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            } else {
                                                // Render each variant individually
                                                ForEach(Array(variants.enumerated()), id: \.offset) { vIdx, vKeys in
                                                    if vIdx > 0 {
                                                        Text("/")
                                                            .font(.system(size: 11, weight: .semibold))
                                                            .foregroundColor(Color.white.opacity(0.40))
                                                    }

                                                    let isRecordingThisVariant = (state.recordingCategory == category && state.recordingIndex == index && state.recordingVariantIndex == vIdx)

                                                    if isRecordingThisVariant {
                                                        RecordingBadgeView(state: state)
                                                    } else {
                                                        HStack(spacing: 4) {
                                                            // Colored tokens for this variant
                                                            let tokens = KeyTokenParser.parse(vKeys)
                                                            HStack(spacing: 3) {
                                                                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                                                                    Text(token.text)
                                                                        .font(.system(size: token.isSpecial ? 11 : 10, weight: .bold, design: .monospaced))
                                                                        .padding(.horizontal, token.isSpecial ? 5 : 4)
                                                                        .padding(.vertical, 2)
                                                                        .foregroundColor(token.color)
                                                                        .background(RoundedRectangle(cornerRadius: 4).fill(token.color.opacity(0.18)))
                                                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(token.color.opacity(0.40), lineWidth: 0.8))
                                                                }
                                                            }

                                                            // Re-record this specific variant button
                                                            Button(action: {
                                                                state.startRecording(category: category, index: index, variantIndex: vIdx)
                                                            }) {
                                                                Image(systemName: "arrow.clockwise")
                                                                    .font(.system(size: 9, weight: .bold))
                                                                    .foregroundColor(accent)
                                                                    .padding(2)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            .help("Re-record this key variant")

                                                            // Delete this specific variant button
                                                            Button(action: {
                                                                state.deleteVariant(category: category, index: index, variantIndex: vIdx)
                                                            }) {
                                                                Image(systemName: "xmark")
                                                                    .font(.system(size: 8, weight: .bold))
                                                                    .foregroundColor(.secondary)
                                                                    .padding(2)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            .help("Delete this key variant")
                                                        }
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 3)
                                                        .background(Color.white.opacity(0.04))
                                                        .cornerRadius(6)
                                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                                    }
                                                }

                                                // Check if currently recording a new alternate
                                                let isRecordingNewAlternate = (state.recordingCategory == category && state.recordingIndex == index && state.recordingVariantIndex == nil)
                                                if isRecordingNewAlternate {
                                                    RecordingBadgeView(state: state)
                                                } else {
                                                    // Button to Add New Alternate Variant
                                                    Button(action: {
                                                        state.startRecording(category: category, index: index, variantIndex: nil)
                                                    }) {
                                                        HStack(spacing: 3) {
                                                            Image(systemName: "plus")
                                                                .font(.system(size: 9, weight: .bold))
                                                            Text("Or")
                                                                .font(.system(size: 10, weight: .bold))
                                                        }
                                                        .foregroundColor(accent)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 3)
                                                        .background(accent.opacity(0.12))
                                                        .cornerRadius(5)
                                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(accent.opacity(0.35), lineWidth: 1))
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .help("Add an alternate key combination for this shortcut (e.g. j / ↓)")
                                                }
                                            }
                                        }

                                        // Conflict Badges
                                        let conflicts = ShortcutConflictDetector.shared.allConflicts(
                                            for: currentKeys,
                                            currentTitle: currentTitle,
                                            inCategories: state.currentCategories,
                                            shortcutsProvider: { state.shortcuts(for: $0) }
                                        )

                                        ForEach(Array(conflicts.enumerated()), id: \.offset) { _, conf in
                                            HStack(spacing: 3) {
                                                Image(systemName: conf.isGlobal ? "bolt.fill" : "exclamationmark.triangle.fill")
                                                    .font(.system(size: 9, weight: .bold))
                                                Text(conf.badgeText)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .lineLimit(1)
                                            }
                                            .foregroundColor(conf.isGlobal ? Color.yellow : Color.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(RoundedRectangle(cornerRadius: 4).fill((conf.isGlobal ? Color.yellow : Color.orange).opacity(0.14)))
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke((conf.isGlobal ? Color.yellow : Color.orange).opacity(0.35), lineWidth: 0.8))
                                            .help(conf.tooltip)
                                        }

                                        // Hide / Unhide Shortcut Button
                                        let isItemHidden = hiddenManager.isItemHidden(bundleID: state.selectedBundleID, category: category, title: currentTitle)
                                        Button(action: {
                                            hiddenManager.toggleItemHidden(bundleID: state.selectedBundleID, category: category, title: currentTitle)
                                        }) {
                                            Image(systemName: isItemHidden ? "eye.slash.fill" : "eye")
                                                .font(.system(size: 11))
                                                .foregroundColor(isItemHidden ? Color.orange : Color.secondary.opacity(0.7))
                                                .padding(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help(isItemHidden ? "Unhide this shortcut in HUD" : "Hide this shortcut from HUD (hide known shortcut)")

                                        // Delete Shortcut Button
                                        Button(action: {
                                            state.deleteShortcut(category: category, index: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .padding(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .help("Delete Shortcut")
                                    }
                                }

                                if !state.filterOnlyConflicts {
                                    // Add Shortcut row button
                                    Button(action: {
                                        state.addShortcut(category: category)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                            Text("Add Shortcut")
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(accent)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.top, 4)
                                }
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Modifier Legend Bar
            HStack(spacing: 14) {
                Text("MODIFIERS:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.trailing, -4)

                ForEach(modifierLegendItems) { item in
                    HStack(spacing: 4) {
                        Text(item.symbol)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(item.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.color.opacity(0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(item.color.opacity(0.35), lineWidth: 0.75)
                            )

                        Text(item.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(minWidth: 650, minHeight: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

class KeybindingEditorWindowController: NSWindowController {
    static let shared = KeybindingEditorWindowController()
    let editorState = EditorState()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 580),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyHUD Keybinding Editor"
        window.collectionBehavior = [.moveToActiveSpace]
        window.minSize = NSSize(width: 600, height: 440)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let view = KeybindingEditorView(state: editorState) { [weak self] in
            self?.close()
        }
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func openEditor(bundleID: String? = nil) {
        editorState.reload(selecting: bundleID)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
