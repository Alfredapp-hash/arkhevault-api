import SwiftUI

struct ControlsPanelView: View {
    @Binding var settings: TypingSettings
    let isDisabled: Bool
    let canStart: Bool
    let isRunning: Bool
    let startButtonTitle: String
    let onStart: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Typing Profile", systemImage: "slider.horizontal.3")
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: AppTheme.Spacing.md) {
                PremiumSliderControl(
                    icon: "speedometer",
                    title: "Typing Speed",
                    subtitle: "Average essay pace — WPM naturally rises and falls",
                    value: $settings.wordsPerMinute,
                    range: TypingSettings.wpmRange,
                    step: 5,
                    valueLabel: "\(Int(settings.wordsPerMinute))",
                    tint: AppTheme.accent
                )

                PremiumSliderControl(
                    icon: "exclamationmark.bubble",
                    title: "Natural Errors",
                    subtitle: "Nearby-key typos with automatic correction",
                    value: Binding(
                        get: { settings.errorRate * 100 },
                        set: { settings.errorRate = $0 / 100 }
                    ),
                    range: 0...10,
                    step: 0.5,
                    valueLabel: String(format: "%.1f%%", settings.errorRate * 100),
                    tint: AppTheme.accentWarm
                )

                CountdownStepperControl(
                    seconds: $settings.countdownSeconds,
                    range: TypingSettings.countdownRange
                )
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.55 : 1)

            Divider()
                .overlay(AppTheme.borderSubtle)

            actionSection

            keyboardHints
        }
        .premiumCard()
    }

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Button(action: onStart) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: settings.runScope == .selection ? "selection.pin.in.out" : "play.fill")
                    Text(startButtonTitle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!canStart || isRunning)
            .keyboardShortcut(.return, modifiers: .command)

            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onStop) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(!isRunning)
                .keyboardShortcut(.escape, modifiers: [])

                Button(action: onClear) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(isRunning)
            }
        }
    }

    private var keyboardHints: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            KeyboardHint(keys: "⌘↩", action: "Start")
            KeyboardHint(keys: "Esc", action: "Stop")
            KeyboardHint(keys: "⇧⌘V", action: "Paste")
        }
        .frame(maxWidth: .infinity)
    }
}

private struct KeyboardHint: View {
    let keys: String
    let action: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(keys)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                        }
                }

            Text(action)
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}
