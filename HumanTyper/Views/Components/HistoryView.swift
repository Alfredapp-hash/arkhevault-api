import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore: RunHistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Text("Run History")
                    .font(AppTheme.titleFont())
                Spacer()
                Button("Clear") { historyStore.clear() }
                    .disabled(historyStore.entries.isEmpty)
                Button("Close") { dismiss() }
            }

            if historyStore.entries.isEmpty {
                Text("No runs yet.")
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(historyStore.entries) { entry in
                    let summary = entry.summary
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(summary.dryRun ? "Dry run" : summary.documentMode.title)
                                .font(AppTheme.headlineFont())
                            Spacer()
                            Text(TypingSettings.formatDuration(summary.duration))
                                .font(AppTheme.captionFont())
                                .foregroundStyle(AppTheme.accent)
                        }
                        Text("\(summary.scope.title) · \(summary.characterCount) chars · \(String(format: "%.0f WPM", summary.estimatedWPM))")
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(summary.textPreview)
                            .font(AppTheme.captionFont())
                            .lineLimit(1)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(width: 520, height: 420)
    }
}
