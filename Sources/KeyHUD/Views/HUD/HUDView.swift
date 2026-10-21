import SwiftUI
import AppKit

// MARK: - SwiftUI HUD View Model & View

class HUDViewModel: ObservableObject {
    @Published var appName: String = ""
    @Published var bundleID: String = ""
    @Published var appIcon: NSImage? = nil
    @Published var groups: [ShortcutGroup] = []
}

struct HUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    let onExecute: (ShortcutItem) -> Void
    let onDismiss: () -> Void

    @ObservedObject var searchState: SearchState
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var favorites = FavoritesManager.shared
    @ObservedObject var hiddenManager = HiddenItemsManager.shared

    var appName: String { viewModel.appName }
    var bundleID: String { viewModel.bundleID }
    var appIcon: NSImage? { viewModel.appIcon }
    var groups: [ShortcutGroup] { viewModel.groups }

    var currentScopeBundleID: String {
        switch searchState.selectedScope {
        case .activeApp:
            return bundleID
        case .ghosttyTool:
            return "com.mitchellh.ghostty"
        case .runningApp(let bID, _, _):
            return bID
        case .aerospace:
            return "aerospace"
        case .macos:
            return "macos"
        }
    }

    var currentScopeStorageKey: String {
        switch searchState.selectedScope {
        case .activeApp:
            return bundleID
        case .ghosttyTool(let category):
            return "ghostty:\(category)"
        case .runningApp(let bID, _, _):
            return bID
        case .aerospace:
            return "aerospace"
        case .macos:
            return "macos"
        }
    }

    var rawScopeGroups: [ShortcutGroup] {
        switch searchState.selectedScope {
        case .activeApp:
            if bundleID == "com.mitchellh.ghostty" {
                // Filter to only categories marked "Shown on Main"
                return groups.filter { settings.isGhosttyCategoryShownOnMain($0.title) }
            }
            return groups
        case .ghosttyTool(let catName):
            let ghosttyGroups = (bundleID == "com.mitchellh.ghostty") ? groups : (CustomShortcutsManager.shared.groups(for: "com.mitchellh.ghostty") ?? [])
            return ghosttyGroups.filter { $0.title == catName }
        case .runningApp(let bID, _, _):
            // Load custom shortcuts or scanned menus for this running app
            var appGroups = CustomShortcutsManager.shared.groups(for: bID) ?? []
            if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bID }) {
                let scanned = MenuScanner.scan(app: running)
                for sc in scanned {
                    if !appGroups.contains(where: { $0.title == sc.title }) {
                        appGroups.append(sc)
                    }
                }
            }
            if bID == "com.mitchellh.ghostty" {
                return appGroups.filter { settings.isGhosttyCategoryShownOnMain($0.title) }
            }
            return appGroups
        case .aerospace:
            return AeroSpaceConfigParser.parse()
        case .macos:
            return MacOSGlobalShortcuts.getGroups()
        }
    }

    var shouldIncludeMenuActions: Bool {
        if searchState.isCommandPaletteActive { return true }
        if settings.commandPaletteMode == CommandPaletteMode.always.rawValue { return true }
        if settings.commandPaletteMode == CommandPaletteMode.searchOnly.rawValue && !searchState.query.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        return false
    }

    var currentScopeGroups: [ShortcutGroup] {
        let bID = currentScopeBundleID
        var baseGroups = rawScopeGroups
        let includeActions = shouldIncludeMenuActions

        baseGroups = baseGroups.compactMap { grp in
            if !searchState.showHiddenItems && hiddenManager.isCategoryHidden(bundleID: bID, category: grp.title) {
                return nil
            }
            let visible = grp.items.filter { item in
                if !includeActions && item.isMenuAction { return false }
                if !searchState.showHiddenItems && hiddenManager.isItemHidden(bundleID: bID, category: grp.title, title: item.title) {
                    return false
                }
                return true
            }
            return visible.isEmpty ? nil : ShortcutGroup(title: grp.title, items: visible)
        }

        let key = currentScopeStorageKey
        let bookmarkedTitles = favorites.bookmarks(for: key)

        if bookmarkedTitles.isEmpty {
            return baseGroups
        }

        var favItems: [ShortcutItem] = []
        var seenTitles = Set<String>()
        for grp in baseGroups {
            for item in grp.items {
                if bookmarkedTitles.contains(item.title) && !seenTitles.contains(item.title) {
                    favItems.append(item)
                    seenTitles.insert(item.title)
                }
            }
        }

        if favItems.isEmpty {
            return baseGroups
        }

        let favGroup = ShortcutGroup(title: "⭐ Favorites", items: favItems)
        return [favGroup] + baseGroups
    }

    var searchableGroups: [ShortcutGroup] {
        switch searchState.activeSearchScope {
        case .current:
            return currentScopeGroups
        case .currentAndSubApps:
            var allGroups = groups
            let bID = currentScopeBundleID
            let includeActions = shouldIncludeMenuActions

            allGroups = allGroups.compactMap { grp in
                if !searchState.showHiddenItems && hiddenManager.isCategoryHidden(bundleID: bID, category: grp.title) {
                    return nil
                }
                let visible = grp.items.filter { item in
                    if !includeActions && item.isMenuAction { return false }
                    if !searchState.showHiddenItems && hiddenManager.isItemHidden(bundleID: bID, category: grp.title, title: item.title) {
                        return false
                    }
                    return true
                }
                return visible.isEmpty ? nil : ShortcutGroup(title: grp.title, items: visible)
            }

            let key = currentScopeStorageKey
            let bookmarkedTitles = favorites.bookmarks(for: key)
            if !bookmarkedTitles.isEmpty {
                var favItems: [ShortcutItem] = []
                for grp in allGroups {
                    for item in grp.items {
                        if bookmarkedTitles.contains(item.title) && !favItems.contains(where: { $0.title == item.title }) {
                            favItems.append(item)
                        }
                    }
                }
                if !favItems.isEmpty {
                    return [ShortcutGroup(title: "⭐ Favorites", items: favItems)] + allGroups
                }
            }
            return allGroups
        case .global:
            var all = groups
            for grp in AeroSpaceConfigParser.parse() {
                if !all.contains(where: { $0.title == grp.title }) {
                    all.append(grp)
                }
            }
            for grp in MacOSGlobalShortcuts.getGroups() {
                if !all.contains(where: { $0.title == grp.title }) {
                    all.append(grp)
                }
            }
            return all
        }
    }

    var filteredGroups: [ShortcutGroup] {
        let q = searchState.query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            return currentScopeGroups
        }
        return searchableGroups.compactMap { group in
            let filteredItems = group.items.filter {
                FuzzyMatcher.matches(pattern: q, target: $0.title) || FuzzyMatcher.matches(pattern: q, target: $0.keys)
            }
            return filteredItems.isEmpty ? nil : ShortcutGroup(title: group.title, items: filteredItems)
        }
    }

    var currentGroupIndex: Int {
        guard !filteredGroups.isEmpty else { return 0 }
        return min(max(0, searchState.selectedGroupIndex), filteredGroups.count - 1)
    }

    var currentItemIndex: Int {
        guard !filteredGroups.isEmpty else { return 0 }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return 0 }
        return min(max(0, searchState.selectedItemIndex), grp.items.count - 1)
    }

    var currentSelectedItem: ShortcutItem? {
        guard !filteredGroups.isEmpty else { return nil }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return nil }
        return grp.items[currentItemIndex]
    }

    var currentTargetForExecution: NSRunningApplication? {
        switch searchState.selectedScope {
        case .runningApp(let bID, _, _):
            return NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bID })
        default:
            return nil
        }
    }

    private func executeCurrentSelection() {
        if let item = currentSelectedItem {
            if let customTarget = currentTargetForExecution {
                ActionExecutor.shared.execute(item: item, targetApp: customTarget)
            } else {
                onExecute(item)
            }
        }
    }

    private func moveSelectionDown() {
        guard !filteredGroups.isEmpty else { return }
        let grp = filteredGroups[currentGroupIndex]
        guard !grp.items.isEmpty else { return }
        if searchState.selectedItemIndex < grp.items.count - 1 {
            searchState.selectedItemIndex += 1
        }
    }

    private func moveSelectionUp() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedItemIndex > 0 {
            searchState.selectedItemIndex -= 1
        }
    }

    private func moveSelectionRight() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedGroupIndex < filteredGroups.count - 1 {
            searchState.selectedGroupIndex += 1
            let newGrp = filteredGroups[searchState.selectedGroupIndex]
            if !newGrp.items.isEmpty {
                searchState.selectedItemIndex = min(searchState.selectedItemIndex, newGrp.items.count - 1)
            } else {
                searchState.selectedItemIndex = 0
            }
        }
    }

    private func moveSelectionLeft() {
        guard !filteredGroups.isEmpty else { return }
        if searchState.selectedGroupIndex > 0 {
            searchState.selectedGroupIndex -= 1
            let newGrp = filteredGroups[searchState.selectedGroupIndex]
            if !newGrp.items.isEmpty {
                searchState.selectedItemIndex = min(searchState.selectedItemIndex, newGrp.items.count - 1)
            } else {
                searchState.selectedItemIndex = 0
            }
        }
    }

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Drag Header / Search Bar
            HStack(spacing: 8) {
                // Interactive Breadcrumb Trail
                HStack(spacing: 6) {
                    if !searchState.scopeHistory.isEmpty {
                        ForEach(Array(searchState.scopeHistory.enumerated()), id: \.offset) { idx, prevScope in
                            Button(action: {
                                searchState.popToHistoryIndex(idx)
                            }) {
                                HStack(spacing: 4) {
                                    Text(prevScope.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.65))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Back to \(prevScope.title)")

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.35))
                        }
                    }

                    // Scope Switcher Dropdown Menu (Current Scope Level)
                    Menu {
                        // SECTION 1: Active App & Sub-tools
                        Section("ACTIVE CONTEXT") {
                            Button(action: {
                                searchState.navigateToScope(.activeApp)
                            }) {
                                HStack {
                                    if let icon = appIcon {
                                        Image(nsImage: icon)
                                    }
                                    Text("\(bundleID == "com.mitchellh.ghostty" ? "Ghostty (Main)" : appName) (Active)")
                                }
                            }

                            // Ghostty TUI Sub-profiles (active context or navigated Ghostty context)
                            let isViewingGhostty = (bundleID == "com.mitchellh.ghostty") || (currentScopeBundleID == "com.mitchellh.ghostty")
                            if isViewingGhostty {
                                let ghosttyGroups = (bundleID == "com.mitchellh.ghostty") ? groups : (CustomShortcutsManager.shared.groups(for: "com.mitchellh.ghostty") ?? [])
                                if !ghosttyGroups.isEmpty {
                                    Menu("Terminal Tools") {
                                        ForEach(ghosttyGroups) { grp in
                                            Button(action: {
                                                searchState.navigateToScope(.ghosttyTool(category: grp.title))
                                            }) {
                                                HStack {
                                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                                    Text(grp.title)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // SECTION 2: Global Tools
                        Section("GLOBAL TOOLS") {
                            Button(action: {
                                searchState.navigateToScope(.aerospace)
                            }) {
                                HStack {
                                    Image(systemName: "macwindow.on.rectangle")
                                    Text("AeroSpace Tiling")
                                }
                            }

                            Button(action: {
                                searchState.navigateToScope(.macos)
                            }) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                    Text("macOS System")
                                }
                            }
                        }

                        // SECTION 3: Other Running Applications
                        let otherApps = RunningAppsTracker.shared.runningApps.filter { $0.bundleIdentifier != bundleID }

                        if !otherApps.isEmpty {
                            Section("OTHER RUNNING APPS") {
                                ForEach(otherApps) { app in
                                    if app.bundleIdentifier == "com.mitchellh.ghostty" {
                                        Menu {
                                            Button(action: {
                                                searchState.navigateToScope(.runningApp(bundleID: app.bundleIdentifier, name: app.localizedName, icon: app.icon))
                                            }) {
                                                HStack {
                                                    Image(nsImage: app.icon)
                                                    Text("Ghostty (Main)")
                                                }
                                            }

                                            let ghosttyGroups = CustomShortcutsManager.shared.groups(for: "com.mitchellh.ghostty") ?? []
                                            if !ghosttyGroups.isEmpty {
                                                Menu("Terminal Tools") {
                                                    ForEach(ghosttyGroups) { grp in
                                                        Button(action: {
                                                            searchState.navigateToScope(.ghosttyTool(category: grp.title))
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                                                Text(grp.title)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(nsImage: app.icon)
                                                Text(app.localizedName)
                                            }
                                        }
                                    } else {
                                        Button(action: {
                                            searchState.navigateToScope(.runningApp(bundleID: app.bundleIdentifier, name: app.localizedName, icon: app.icon))
                                        }) {
                                            HStack {
                                                Image(nsImage: app.icon)
                                                Text(app.localizedName)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            switch searchState.selectedScope {
                            case .activeApp:
                                if let icon = appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                }
                                Text(bundleID == "com.mitchellh.ghostty" ? "Ghostty (Main)" : appName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            case .ghosttyTool(let catName):
                                Image(systemName: "terminal")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(accent)
                                Text("Ghostty: \(catName)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            case .runningApp(_, let name, let icon):
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            case .aerospace:
                                Image(systemName: "macwindow.on.rectangle")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(accent)
                                Text("AeroSpace Tiling")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            case .macos:
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(accent)
                                Text("macOS System")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            // High-contrast native dropdown chevron pill
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.95))
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.32), lineWidth: 1.2)
                        )
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .help("Application & Scope Menu: Switch between active app, terminal tools, global tools (AeroSpace, macOS), or running apps")
                }
                .menuStyle(BorderlessButtonMenuStyle())

                Spacer()

                // Search Field Container with Scope Filter Button
                HStack(spacing: 6) {
                    // Search Scope Menu Button
                    Menu {
                        ForEach(SearchScope.allCases) { scope in
                            Button(action: {
                                searchState.activeSearchScope = scope
                            }) {
                                HStack {
                                    Image(systemName: scope.icon)
                                    Text(scope.rawValue)
                                    if searchState.activeSearchScope == scope {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: searchState.activeSearchScope.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(accent)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(5)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .help("Search Scope: \(searchState.activeSearchScope.rawValue) — Filter search between Current View, Sub-tools, or Global")

                    SearchBarView(
                        text: $searchState.query,
                        onMoveDown: moveSelectionDown,
                        onMoveUp: moveSelectionUp,
                        onMoveLeft: moveSelectionLeft,
                        onMoveRight: moveSelectionRight,
                        onCommit: executeCurrentSelection,
                        onEscape: onDismiss
                    )
                    .frame(height: 22)

                    if !searchState.query.isEmpty {
                        Button(action: { searchState.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Clear search filter (Esc)")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .cornerRadius(8)
                .frame(minWidth: 200, idealWidth: 320, maxWidth: 420)

                // Show / Hide Known Shortcuts Button
                Button(action: {
                    searchState.showHiddenItems.toggle()
                    HUDWindowController.shared.applyScreenPercentageFrame(groups: currentScopeGroups)
                }) {
                    Image(systemName: searchState.showHiddenItems ? "eye.fill" : "eye.slash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(searchState.showHiddenItems ? accent : .gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help(searchState.showHiddenItems ? "Hide Known Shortcuts: Click to hide common/known shortcuts" : "Reveal Hidden Shortcuts: Click to show all hidden shortcuts for this app")

                // Command Palette Toggle Button
                Button(action: {
                    searchState.isCommandPaletteActive.toggle()
                    HUDWindowController.shared.applyScreenPercentageFrame(groups: currentScopeGroups)
                }) {
                    Image(systemName: searchState.isCommandPaletteActive ? "command.circle.fill" : "command.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(searchState.isCommandPaletteActive ? accent : .gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help(searchState.isCommandPaletteActive ? "Command Palette Active: Click to return to shortcuts only" : "Command Palette Mode: Click to index and show all application menu actions (Paletro-style)")

                // Pin Button
                Button(action: {
                    settings.isPinned.toggle()
                }) {
                    Image(systemName: settings.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(settings.isPinned ? accent : .gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help(settings.isPinned ? "Unpin HUD: Click to auto-close HUD when clicking shortcuts" : "Pin HUD: Click to keep HUD floating on screen while running shortcuts")

                // Export to Markdown Button
                Button(action: {
                    let menu = NSMenu(title: "Export")
                    menu.addItem(BlockMenuItem(title: "Copy Markdown to Clipboard", iconName: "doc.on.clipboard") {
                        MarkdownExporter.copyToClipboard(appName: appName, groups: currentScopeGroups)
                    })
                    menu.addItem(BlockMenuItem(title: "Save to Documents (KeyHUD)", iconName: "folder") {
                        _ = MarkdownExporter.saveToFile(appName: appName, groups: currentScopeGroups, destination: .documents)
                    })
                    menu.addItem(BlockMenuItem(title: "Save to XDG Data (\(XDG.dataHome)/keyhud)", iconName: "shippingbox") {
                        _ = MarkdownExporter.saveToFile(appName: appName, groups: currentScopeGroups, destination: .xdgData)
                    })
                    menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Export Cheatsheet: Copy formatted Markdown to clipboard or save to Documents folder")

                // Keyboard Heatmap Button
                Button(action: {
                    HUDWindowController.shared.hide()
                    SettingsWindowController.shared.openSettings(selectingTab: .shortcuts, bundleID: bundleID)
                }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Keyboard Heatmap: Visual ANSI keyboard layout and modifier conflict inspector")

                // Edit Shortcuts Button
                Button(action: {
                    HUDWindowController.shared.hide()
                    SettingsWindowController.shared.openSettings(selectingTab: .shortcuts, bundleID: bundleID)
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Keybinding Editor: Customize, record, or add shortcuts and categories for \(appName)")

                // Close Button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close KeyHUD (Esc)")
            }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider()
                .background(Color.white.opacity(0.15))

            // Resizable Columns Content
            GeometryReader { geo in
                if filteredGroups.isEmpty {
                    VStack {
                        Spacer()
                        if !AXIsProcessTrusted() {
                            VStack(spacing: 16) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.orange)

                                Text("Accessibility Permission Required")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("macOS requires Accessibility permission for KeyHUD to auto-detect shortcuts from native apps like \(appName).\n\nIf you already turned it ON in System Settings, click Relaunch KeyHUD below so macOS applies the permission token.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.92))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(maxWidth: 440)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        HUDWindowController.shared.hide()
                                        AppDelegate.shared?.relaunchApp()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Relaunch KeyHUD")
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(accent)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Relaunch KeyHUD to re-check Accessibility permissions")

                                    Button(action: {
                                        HUDWindowController.shared.hide()
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "gearshape")
                                            Text("Open Privacy Settings")
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.18))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help("Open macOS Privacy & Security Settings to grant Accessibility access")
                                }
                                .padding(.top, 4)
                            }
                            .padding(28)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.16, green: 0.16, blue: 0.20))
                                    .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                            )
                        } else {
                            VStack(spacing: 12) {
                                Text("No shortcuts found")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                } else {
                    ScrollViewReader { horizProxy in
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { groupIndex, group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        let isCatHidden = hiddenManager.isCategoryHidden(bundleID: currentScopeBundleID, category: group.title)
                                        HStack(spacing: 5) {
                                            Text(group.title.uppercased())
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(group.title.contains("Favorites") ? Color.yellow : accent)

                                            if isCatHidden {
                                                Image(systemName: "eye.slash.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        .padding(.bottom, 2)

                                        ScrollViewReader { vertProxy in
                                            ScrollView(.vertical, showsIndicators: true) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, item in
                                                        let isSelected = (currentGroupIndex == groupIndex && currentItemIndex == itemIndex)
                                                        let isHovered = (searchState.hoveredItemId == item.id)
                                                        let isBookmarked = favorites.isBookmarked(scopeKey: currentScopeStorageKey, title: item.title)
                                                        let isItemHidden = hiddenManager.isItemHidden(bundleID: currentScopeBundleID, category: group.title, title: item.title)

                                                        ShortcutRow(
                                                            item: item,
                                                            isSelected: isSelected,
                                                            isHovered: isHovered,
                                                            isBookmarked: isBookmarked,
                                                            isHiddenShortcut: isItemHidden,
                                                            isOddRow: (itemIndex % 2 != 0),
                                                            accentColor: accent,
                                                            onSelect: {
                                                                searchState.selectedGroupIndex = groupIndex
                                                                searchState.selectedItemIndex = itemIndex
                                                                if let customTarget = currentTargetForExecution {
                                                                  ActionExecutor.shared.execute(item: item, targetApp: customTarget)
                                                                } else {
                                                                    onExecute(item)
                                                                }
                                                            },
                                                            onToggleBookmark: {
                                                                favorites.toggleBookmark(scopeKey: currentScopeStorageKey, title: item.title)
                                                                HUDWindowController.shared.applyScreenPercentageFrame(groups: currentScopeGroups)
                                                            },
                                                            onHover: { hovering in
                                                                searchState.hoveredItemId = hovering ? item.id : nil
                                                            }
                                                        )
                                                        .id(item.id)
                                                    }
                                                }
                                                .padding(.trailing, 4)
                                            }
                                            .frame(maxHeight: .infinity)
                                            .onChange(of: searchState.selectedItemIndex) {
                                                if currentGroupIndex == groupIndex && currentItemIndex < group.items.count {
                                                    withAnimation(.easeInOut(duration: 0.12)) {
                                                        vertProxy.scrollTo(group.items[currentItemIndex].id, anchor: nil)
                                                    }
                                                }
                                            }
                                            .onChange(of: searchState.selectedGroupIndex) {
                                                if currentGroupIndex == groupIndex && currentItemIndex < group.items.count {
                                                    withAnimation(.easeInOut(duration: 0.12)) {
                                                        vertProxy.scrollTo(group.items[currentItemIndex].id, anchor: nil)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 260)
                                    .frame(maxHeight: .infinity)
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(10)
                                    .id(group.id)
                                }
                            }
                        }
                        .padding(18)
                        .frame(minHeight: geo.size.height)
                        .onChange(of: searchState.selectedGroupIndex) {
                            if currentGroupIndex < filteredGroups.count {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    horizProxy.scrollTo(filteredGroups[currentGroupIndex].id, anchor: nil)
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Modifiers Legend Bar
            Divider()
                .background(Color.white.opacity(0.12))

            HStack(spacing: 16) {
                Text("MODIFIERS:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.45))
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
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
        }
        .frame(minWidth: 860, minHeight: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: searchState.selectedScope) {
            HUDWindowController.shared.applyScreenPercentageFrame(groups: currentScopeGroups)
        }
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.85)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
}
