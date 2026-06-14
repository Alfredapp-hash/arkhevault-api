import SwiftUI

struct AccessibilityBannerView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Accessibility access required")
                    .font(AppTheme.headlineFont())
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Human Typer simulates keystrokes via macOS Accessibility APIs. Grant access to type into Word and other apps.")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppTheme.Spacing.md)

            Button(action: onOpenSettings) {
                Label("Open Settings", systemImage: "gear")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(AppTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(AppTheme.warning.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .strokeBorder(AppTheme.warning.opacity(0.35), lineWidth: 1)
                }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
