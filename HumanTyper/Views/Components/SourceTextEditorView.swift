import AppKit
import SwiftUI

struct SourceTextEditorView: View {
    @Binding var text: String
    let isDisabled: Bool
    let settings: TypingSettings

    @FocusState private var isFocused: Bool

    private var characterCount: Int { text.count }
    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count
    }

    private var estimatedDuration: String {
        TypingSettings.formatDuration(settings.estimatedDuration(forCharacterCount: characterCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Label("Source Text", systemImage: "doc.text.fill")
                    .font(AppTheme.headlineFont())
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if !text.isEmpty {
                    Text("~\(estimatedDuration)")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background {
                            Capsule().fill(AppTheme.accent.opacity(0.12))
                        }
                }
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste or type the text you want Human Typer to enter in your target app…")
                        .font(AppTheme.monoFont())
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(AppTheme.Spacing.lg)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(AppTheme.monoFont())
                    .scrollContentBackground(.hidden)
                    .padding(AppTheme.Spacing.md)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.6 : 1)
            }
            .frame(minHeight: 220, maxHeight: .infinity)
            .premiumInset()

            HStack(spacing: AppTheme.Spacing.lg) {
                StatPill(icon: "character.cursor.ibeam", label: "Characters", value: "\(characterCount)")
                StatPill(icon: "text.word.spacing", label: "Words", value: "\(wordCount)")
                Spacer()

                if !isDisabled {
                    Button("Paste") {
                        if let clipboard = NSPasteboard.general.string(forType: .string) {
                            text = clipboard
                        }
                    }
                    .buttonStyle(GhostActionButtonStyle())
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                }
            }
        }
        .premiumCard()
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                Text(value)
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}
