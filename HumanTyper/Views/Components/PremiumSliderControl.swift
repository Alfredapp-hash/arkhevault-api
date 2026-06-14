import SwiftUI

struct PremiumSliderControl: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                            .fill(tint.opacity(0.14))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.headlineFont())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()

                Text(valueLabel)
                    .font(AppTheme.statFont())
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35), value: valueLabel)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tint)
        }
        .padding(AppTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                        .strokeBorder(AppTheme.borderSubtle, lineWidth: 1)
                }
        }
    }
}

struct CountdownStepperControl: View {
    @Binding var seconds: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Image(systemName: "hourglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accentWarm)
                .frame(width: 28, height: 28)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                        .fill(AppTheme.accentWarm.opacity(0.14))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Countdown")
                    .font(AppTheme.headlineFont())
                Text("Time to switch to your target app")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: AppTheme.Spacing.sm) {
                stepperButton(systemName: "minus", enabled: seconds > range.lowerBound) {
                    seconds = max(range.lowerBound, seconds - 1)
                }

                Text("\(seconds)s")
                    .font(AppTheme.statFont())
                    .foregroundStyle(AppTheme.accentWarm)
                    .frame(minWidth: 44)
                    .monospacedDigit()

                stepperButton(systemName: "plus", enabled: seconds < range.upperBound) {
                    seconds = min(range.upperBound, seconds + 1)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                        .strokeBorder(AppTheme.borderSubtle, lineWidth: 1)
                }
        }
    }

    private func stepperButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? AppTheme.textPrimary : AppTheme.textTertiary)
        .background {
            Circle()
                .fill(Color.white.opacity(enabled ? 0.08 : 0.03))
        }
        .disabled(!enabled)
    }
}
