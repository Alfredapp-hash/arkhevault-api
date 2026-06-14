import SwiftUI

struct CountdownRingView: View {
    let remaining: Int
    let total: Int

    @State private var pulse = false

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(total - remaining) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.borderSubtle, lineWidth: 6)
                .frame(width: 88, height: 88)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.accent, AppTheme.accentSecondary, AppTheme.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 88, height: 88)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            VStack(spacing: 0) {
                Text("\(remaining)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text("sec")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .scaleEffect(pulse ? 1.04 : 1)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
        .onDisappear { pulse = false }
    }
}
