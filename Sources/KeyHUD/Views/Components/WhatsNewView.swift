import SwiftUI
import AppKit

// MARK: - What's New View & Window Controller

struct WhatsNewView: View {
    let onClose: () -> Void
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        let accent = settings.currentAccentColor

        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 56, height: 56)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("What's New in KeyHUD")
                            .font(.system(size: 20, weight: .bold))

                        Text("v\(ReleaseNotes.currentVersion)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.14))
                            .cornerRadius(5)
                    }

                    Text(ReleaseNotes.summary)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Release Notes Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(ReleaseNotes.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(accent)
                                    .frame(width: 18)

                                Text(section.category)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(section.items, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 12))
                                        Text(item)
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.leading, 26)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
            }
            .frame(maxHeight: 340)

            Divider()

            // Footer Button
            HStack {
                Spacer()
                Button(action: onClose) {
                    Text("Continue")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(BorderedProminentButtonStyle())
                .tint(accent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .frame(width: 580, height: 530)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

class WhatsNewWindowController: NSWindowController {
    static let shared = WhatsNewWindowController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 530),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "What's New in KeyHUD"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        super.init(window: window)

        let contentView = WhatsNewView(onClose: { [weak self] in
            self?.window?.close()
        })
        window.contentView = NSHostingView(rootView: contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window = window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
