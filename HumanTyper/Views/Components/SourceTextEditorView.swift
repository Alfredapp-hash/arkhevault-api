import AppKit
import SwiftUI

struct SourceTextEditorView: View {
    @Binding var text: String
    @Binding var selection: TextSelectionState
    @Binding var runScope: TypingRunScope
    @Binding var queue: [TypingQueueItem]
    let isDisabled: Bool
    let settings: TypingSettings

    private var activeText: String {
        TextRunResolver.resolveText(
            fullText: text,
            scope: runScope,
            selection: selection,
            queue: queue
        ) ?? text
    }

    private var estimatedDuration: String {
        TypingSettings.formatDuration(settings.estimatedDuration(forText: activeText))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            headerRow
            editorArea
            if runScope == .queued {
                TypingQueueView(
                    queue: $queue,
                    fullText: text,
                    selection: selection,
                    isDisabled: isDisabled
                )
            }
            footerRow
        }
        .premiumCard()
    }

    private var headerRow: some View {
        HStack {
            Label("Source Text", systemImage: "doc.text.fill")
                .font(AppTheme.headlineFont())
            Spacer()
            if !activeText.isEmpty {
                Text("~\(estimatedDuration)")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background { Capsule().fill(AppTheme.accent.opacity(0.12)) }
            }
        }
    }

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Paste your essay. Highlight a section, queue parts, or type from cursor.")
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
            Text("\(selection.selectedText(in: text)?.count ?? 0) selected")
                .font(AppTheme.captionFont())
        }
        .foregroundStyle(AppTheme.accentWarm)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background { Capsule().fill(AppTheme.accentWarm.opacity(0.15)) }
    }

    private var footerRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.lg) {
                stat("Characters", "\(text.count)")
                stat("Words", "\(text.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count)")
                if selection.hasSelection {
                    stat("Selected", "\(selection.selectedText(in: text)?.count ?? 0)", highlight: true)
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
                }
            }

            Picker("Scope", selection: $runScope) {
                ForEach(TypingRunScope.allCases) { scope in
                    Label(scope.title, systemImage: scope.icon).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled)

            if runScope == .selection && !selection.hasSelection {
                Text("Highlight text to type a selection only.")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.warning)
            }
            if runScope == .fromCursor {
                Text("Place the cursor or highlight from the start point through the end.")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func stat(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(AppTheme.textTertiary)
            Text(value).font(AppTheme.captionFont()).foregroundStyle(highlight ? AppTheme.accentWarm : AppTheme.textSecondary).monospacedDigit()
        }
    }
}
