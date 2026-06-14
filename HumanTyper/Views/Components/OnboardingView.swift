import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var step = 0

    private let steps: [(icon: String, title: String, body: String)] = [
        ("doc.on.clipboard", "Paste your text", "Paste an essay, email, or any text you want typed into another app."),
        ("selection.pin.in.out", "Choose what to type", "Type everything, a highlighted selection, from your cursor, or queued sections."),
        ("lock.shield", "Grant Accessibility", "Human Typer needs Accessibility access to simulate keystrokes in Word and other apps."),
        ("arrow.right.circle", "Switch and start", "Click Start, switch to your target app during the countdown, and watch it type naturally.")
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Text("Welcome to Human Typer")
                .font(AppTheme.titleFont())

            let current = steps[step]
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: current.icon)
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.accent)
                Text(current.title)
                    .font(AppTheme.headlineFont())
                Text(current.body)
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .frame(height: 180)

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(SecondaryActionButtonStyle())
                }
                Spacer()
                Button(step == steps.count - 1 ? "Get Started" : "Next") {
                    if step == steps.count - 1 {
                        onComplete()
                        isPresented = false
                    } else {
                        step += 1
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(width: 480)
    }
}
