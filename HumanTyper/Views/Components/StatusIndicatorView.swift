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
                statusIconView
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(AppTheme.headlineFont())
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.interpolate)

                    Text(statusSubtitle)
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .contentTransition(.interpolate)
                }

                Spacer()

                if case .countdown(let remaining) = status {
                    CountdownRingView(remaining: remaining, total: countdownTotal)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if showsProgressBar {
                VStack(spacing: AppTheme.Spacing.sm) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.06))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.accent, AppTheme.accentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geometry.size.width * progress))
                                .animation(.easeInOut(duration: 0.25), value: progress)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(typedCharacters) / \(totalCharacters) characters")
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textTertiary)
                            .monospacedDigit()

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.accent)
                            .monospacedDigit()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: statusAnimationKey)
    }

    @ViewBuilder
    private var statusIconView: some View {
        ZStack {
            Circle()
                .fill(statusTint.opacity(0.15))

            if case .typing = status {
                ProgressView()
                    .controlSize(.small)
                    .tint(statusTint)
            } else {
                Image(systemName: statusIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusTint)
                    .symbolEffect(.bounce, value: statusAnimationKey)
            }
        }
    }

    private var showsProgressBar: Bool {
        switch status {
        case .typing(let scope):
            return totalCharacters > 0
        default:
            return false
        }
    }

    private var statusAnimationKey: String {
        switch status {
        case .idle: return "idle"
        case .countdown(let r): return "countdown-\(r)"
        case .typing(let scope): return "typing-\(scope)-\(typedCharacters)"
        case .completed: return "completed"
        case .cancelled: return "cancelled"
        case .failed(let m): return "failed-\(m)"
        }
    }

    private var statusTitle: String {
        switch status {
        case .idle: return "Ready"
        case .countdown: return "Get ready"
        case .typing(let scope):
            return scope == .selection ? "Typing selection" : "Typing in progress"
        case .completed: return "Complete"
        case .cancelled: return "Stopped"
        case .failed: return "Something went wrong"
        }
    }

    private var statusSubtitle: String {
        switch status {
        case .idle:
            return "Paste your text and press Start when you're ready."
        case .countdown(let remaining):
            return "Switch to Word or your target app now — \(remaining)s remaining."
        case .typing(let scope):
            return scope == .selection
                ? "Writing your highlighted passage with natural essay rhythm."
                : "Writing naturally — WPM varies with flow, pauses, and planning."
        case .completed:
            return "All characters have been typed successfully."
        case .cancelled:
            return "Typing was stopped before completion."
        case .failed(let message):
            return message
        }
    }

    private var statusIcon: String {
        switch status {
        case .idle: return "circle.dashed"
        case .countdown: return "timer"
        case .typing: return "keyboard.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "stop.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusTint: Color {
        switch status {
        case .completed: return AppTheme.success
        case .failed: return AppTheme.danger
        case .cancelled: return AppTheme.warning
        case .countdown, .typing: return AppTheme.accent
        case .idle: return AppTheme.textSecondary
        }
    }
}
