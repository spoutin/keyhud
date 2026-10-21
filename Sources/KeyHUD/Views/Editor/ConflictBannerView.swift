import SwiftUI
import AppKit

// MARK: - Conflict Summary Banner View

struct ConflictSummaryBannerView: View {
    @ObservedObject var state: EditorState
    let accent: Color

    var body: some View {
        let conflicts = state.allConflictSummaries()
        if !conflicts.isEmpty {
            let internalCount = conflicts.filter { $0.conflicts.contains(where: { !$0.isGlobal }) }.count
            let globalCount = conflicts.filter { $0.conflicts.contains(where: { $0.isGlobal }) }.count

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(conflicts.count) Hotkey Collision\(conflicts.count == 1 ? "" : "s") Detected")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.orange)

                        Text("\(internalCount) app duplicate\(internalCount == 1 ? "" : "s"), \(globalCount) system collision\(globalCount == 1 ? "" : "s") in \(state.displayName(for: state.selectedBundleID)).")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.85))
                    }

                    Spacer()

                    // Expand / Collapse Details Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            state.isConflictDetailsExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(state.isConflictDetailsExpanded ? "Hide Details" : "View Details (\(conflicts.count))")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: state.isConflictDetailsExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange.opacity(0.35), lineWidth: 0.8))
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Filter Only Conflicting Shortcuts Button
                    Button(action: {
                        state.filterOnlyConflicts.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: state.filterOnlyConflicts ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 11, weight: .semibold))
                            Text(state.filterOnlyConflicts ? "Showing Conflicts Only" : "Filter Conflicting Rows")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(state.filterOnlyConflicts ? .black : Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(state.filterOnlyConflicts ? Color.orange : Color.white.opacity(0.12))
                        .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Expanded Breakdown List
                if state.isConflictDetailsExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Divider().background(Color.orange.opacity(0.3))

                        ForEach(conflicts) { item in
                            HStack(alignment: .center, spacing: 8) {
                                // Key Badges
                                let tokens = KeyTokenParser.parse(item.keys)
                                HStack(spacing: 2) {
                                    ForEach(Array(tokens.enumerated()), id: \.offset) { _, t in
                                        Text(t.text)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .foregroundColor(t.color)
                                            .background(RoundedRectangle(cornerRadius: 3).fill(t.color.opacity(0.20)))
                                    }
                                }

                                Text("\"\(item.title)\"")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)

                                Text("in [\(item.category)]")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)

                                ForEach(Array(item.conflicts.enumerated()), id: \.offset) { _, conf in
                                    Text(conf.badgeText)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(conf.isGlobal ? Color.yellow : Color.orange)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.40), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
    }
}
