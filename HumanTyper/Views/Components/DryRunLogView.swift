import SwiftUI

struct DryRunLogView: View {
    let log: TypingRunLog

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Dry Run Log")
                .font(AppTheme.headlineFont())

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(log.events.suffix(120).enumerated()), id: \.offset) { _, event in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Text(event.kind.rawValue)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(color(for: event.kind))
                                .frame(width: 72, alignment: .leading)
                            Text(event.detail)
                                .font(AppTheme.captionFont())
                                .foregroundStyle(AppTheme.textSecondary)
                            if let delay = event.delay {
                                Text(String(format: "%.2fs", delay))
                                    .font(AppTheme.captionFont())
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .fill(Color.white.opacity(0.03))
        }
    }

    private func color(for kind: TypingRunEvent.Kind) -> Color {
        switch kind {
        case .typo, .revision: return AppTheme.accentWarm
        case .pause: return AppTheme.accent
        case .paste: return AppTheme.warning
        default: return AppTheme.textTertiary
        }
    }
}
