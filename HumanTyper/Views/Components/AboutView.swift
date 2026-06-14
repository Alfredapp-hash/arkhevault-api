import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent)
            Text("Human Typer")
                .font(AppTheme.titleFont())
            Text("Version 1.1")
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textSecondary)
            Text("Natural keystroke simulation for macOS. Types into any focused app with human-like rhythm, errors, and pauses.")
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button("Close") { dismiss() }
                .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(width: 380)
    }
}
