import SwiftUI
import AppKit

// MARK: - Live Recording Badge View

struct RecordingBadgeView: View {
    @ObservedObject var state: EditorState

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(Color.red).frame(width: 8, height: 8)

            // Accumulated sequence tokens
            if !state.recordingSequence.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(state.recordingSequence.enumerated()), id: \.offset) { _, stroke in
                        let tokens = KeyTokenParser.parse(stroke)
                        ForEach(Array(tokens.enumerated()), id: \.offset) { _, t in
                            Text(t.text)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundColor(t.color)
                                .background(RoundedRectangle(cornerRadius: 4).fill(t.color.opacity(0.22)))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(t.color.opacity(0.5), lineWidth: 1))
                        }
                    }
                }
            }

            // Live held modifiers
            if !state.liveModifiers.isEmpty {
                let liveTokens = KeyTokenParser.parse(state.liveModifiers)
                HStack(spacing: 3) {
                    ForEach(Array(liveTokens.enumerated()), id: \.offset) { _, token in
                        Text(token.text)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .foregroundColor(token.color)
                            .background(RoundedRectangle(cornerRadius: 4).fill(token.color.opacity(0.25)))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(token.color.opacity(0.6), lineWidth: 1))
                    }
                    Text("...")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if state.recordingSequence.isEmpty {
                Text("Type keys...")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }

            // Backspace icon to undo last stroke
            if !state.recordingSequence.isEmpty {
                Button(action: { state.removeLastRecordedToken() }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete last stroke (⌫)")
            }

            // Prominent Green Done button to finish via mouse click
            Button(action: { state.commitRecording() }) {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Done")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green)
                .cornerRadius(5)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Click to finish recording")

            // Cancel button
            Button(action: { state.stopRecording() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Cancel recording (Esc)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.6), lineWidth: 1.2))
    }
}
