import SwiftUI

struct StatusIndicatorView: View {
    let status: TypingStatus
    let progress: Double
    let totalCharacters: Int
    let typedCharacters: Int
    let countdownTotal: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                statusIconView.frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle).font(AppTheme.headlineFont())
                    Text(statusSubtitle).font(AppTheme.captionFont()).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if case .countdown(let remaining) = status {
                    CountdownRingView(remaining: remaining, total: countdownTotal)
                }
            }

            if showsProgressBar {
                ProgressView(value: progress)
                    .tint(AppTheme.accent)
                HStack {
                    Text("\(typedCharacters) / \(totalCharacters) characters")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textTertiary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.accent)
                        .monospacedDigit()
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(statusTint.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .strokeBorder(statusTint.opacity(0.25), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private var statusIconView: some View {
        ZStack {
            Circle().fill(statusTint.opacity(0.15))
            if case .typing = status {
                ProgressView().controlSize(.small).tint(statusTint)
            } else if case .stopping = status {
                Image(systemName: "stop.circle").foregroundStyle(AppTheme.warning)
            } else {
                Image(systemName: statusIcon).foregroundStyle(statusTint)
            }
        }
    }

    private var showsProgressBar: Bool {
        if case .typing = status { return totalCharacters > 0 }
        return false
    }

    private var statusTitle: String {
        switch status {
        case .idle: return "Ready"
        case .countdown: return "Get ready"
        case .typing(let scope): return scope == .selection ? "Typing selection" : "Typing in progress"
        case .stopping: return "Stopping…"
        case .completed: return "Complete"
        case .cancelled: return "Stopped"
        case .failed: return "Something went wrong"
        }
    }

    private var statusSubtitle: String {
        switch status {
        case .idle: return "Paste text, choose scope, and press Start."
        case .countdown(let remaining): return "Switch to your target app — \(remaining)s remaining."
        case .typing: return "WPM is varying naturally with essay rhythm."
        case .stopping: return "Cancelling keystroke session…"
        case .completed: return "See the run summary for WPM, typos, and pauses."
        case .cancelled: return "Typing was stopped before completion."
        case .failed(let message): return message
        }
    }

    private var statusIcon: String {
        switch status {
        case .idle: return "circle.dashed"
        case .countdown: return "timer"
        case .typing: return "keyboard.fill"
        case .stopping: return "stop.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "stop.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusTint: Color {
        switch status {
        case .completed: return AppTheme.success
        case .failed: return AppTheme.danger
        case .cancelled, .stopping: return AppTheme.warning
        case .countdown, .typing: return AppTheme.accent
        case .idle: return AppTheme.textSecondary
        }
    }
}
