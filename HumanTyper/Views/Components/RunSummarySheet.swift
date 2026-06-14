import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RunSummarySheet: View {
    let summary: RunSummary
    let log: TypingRunLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text(summary.dryRun ? "Dry Run Complete" : "Run Complete")
                .font(AppTheme.titleFont())

            Grid(alignment: .leading, horizontalSpacing: AppTheme.Spacing.xl, verticalSpacing: AppTheme.Spacing.sm) {
                summaryRow("Duration", TypingSettings.formatDuration(summary.duration))
                summaryRow("Characters", "\(summary.characterCount)")
                summaryRow("Actual WPM", String(format: "%.0f", summary.estimatedWPM))
                summaryRow("Typos", "\(summary.typoCount)")
                summaryRow("Revisions", "\(summary.revisionCount)")
                summaryRow("Pauses", "\(summary.pauseCount)")
                summaryRow("Mode", summary.documentMode.title)
                summaryRow("Scope", summary.scope.title)
                if let app = summary.targetAppName {
                    summaryRow("Target app", app)
                }
            }

            Text("Preview: \(summary.textPreview)")
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            HStack {
                Button("Export JSON") { export(json: true) }
                Button("Export CSV") { export(json: false) }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(width: 460)
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).font(AppTheme.captionFont()).foregroundStyle(AppTheme.textTertiary)
            Text(value).font(AppTheme.headlineFont()).monospacedDigit()
        }
    }

    private func export(json: Bool) {
        let content = json ? RunLogExporter.exportJSON(log) : RunLogExporter.exportCSV(log)
        guard let content else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = json ? [.json] : [.commaSeparatedText]
        panel.nameFieldStringValue = json ? "human-typer-log.json" : "human-typer-log.csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
