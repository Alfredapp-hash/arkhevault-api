import AppKit
import SwiftUI

struct SourceTextEditorView: View {
    @Binding var text: String
    @Binding var selection: TextSelectionState
    @Binding var runScope: TypingRunScope
    let isDisabled: Bool
    let settings: TypingSettings

    private var characterCount: Int { text.count }
    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count
    }

    private var activeText: String {
        if runScope == .selection, let selected = selection.selectedText(in: text) {
            return selected
        }
        return text
    }

    private var estimatedDuration: String {
        TypingSettings.formatDuration(settings.estimatedDuration(forText: activeText))
    }

    private var selectionCharacterCount: Int {
        selection.selectedText(in: text)?.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            headerRow
            editorArea
            footerRow
        }
        .premiumCard()
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .animation(.easeInOut(duration: 0.2), value: selection.hasSelection)
    }

    private var headerRow: some View {
        HStack {
            Label("Source Text", systemImage: "doc.text.fill")
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            if !activeText.isEmpty {
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
    }

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Paste your essay, then highlight a section to type just that part — or run the full text.")
                    .font(AppTheme.monoFont())
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(AppTheme.Spacing.lg)
                    .allowsHitTesting(false)
            }

            SelectableTextEditor(text: $text, selection: $selection, isDisabled: isDisabled)
                .padding(AppTheme.Spacing.md)
                .opacity(isDisabled ? 0.6 : 1)
        }
        .frame(minHeight: 220, maxHeight: .infinity)
        .premiumInset()
        .overlay(alignment: .topTrailing) {
            if selection.hasSelection && !isDisabled {
                selectionBadge
                    .padding(AppTheme.Spacing.md)
            }
        }
    }

    private var selectionBadge: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "selection.pin.in.out")
                .font(.system(size: 10, weight: .semibold))
            Text("\(selectionCharacterCount) selected")
                .font(AppTheme.captionFont())
        }
        .foregroundStyle(AppTheme.accentWarm)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background {
            Capsule()
                .fill(AppTheme.accentWarm.opacity(0.15))
                .overlay {
                    Capsule().strokeBorder(AppTheme.accentWarm.opacity(0.35), lineWidth: 1)
                }
        }
    }

    private var footerRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.lg) {
                StatPill(icon: "character.cursor.ibeam", label: "Characters", value: "\(characterCount)")
                StatPill(icon: "text.word.spacing", label: "Words", value: "\(wordCount)")

                if selection.hasSelection {
                    StatPill(
                        icon: "selection.pin.in.out",
                        label: "Selection",
                        value: "\(selectionCharacterCount)",
                        highlight: true
                    )
                }

                Spacer()

                if !isDisabled {
                    Button("Paste") {
                        if let clipboard = NSPasteboard.general.string(forType: .string) {
                            text = clipboard
                            selection = TextSelectionState()
                        }
                    }
                    .buttonStyle(GhostActionButtonStyle())
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                }
            }

            scopePicker
        }
    }

    private var scopePicker: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Type")
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textTertiary)

            Picker("Scope", selection: $runScope) {
                ForEach(TypingRunScope.allCases) { scope in
                    Label(scope.title, systemImage: scope.icon)
                        .tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(isDisabled)

            if runScope == .selection && !selection.hasSelection {
                Text("Highlight text above")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.warning)
            }
        }
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    var highlight = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(highlight ? AppTheme.accentWarm : AppTheme.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                Text(value)
                    .font(AppTheme.captionFont())
                    .foregroundStyle(highlight ? AppTheme.accentWarm : AppTheme.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}
