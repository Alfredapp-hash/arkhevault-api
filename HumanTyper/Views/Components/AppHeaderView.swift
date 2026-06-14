import SwiftUI

struct AppHeaderView: View {
    let hasAccessibility: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "keyboard.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Human Typer")
                    .font(AppTheme.titleFont())
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Natural keystroke simulation for any focused app")
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: AppTheme.Spacing.sm) {
                Circle()
                    .fill(hasAccessibility ? AppTheme.success : AppTheme.warning)
                    .frame(width: 8, height: 8)
                    .shadow(color: (hasAccessibility ? AppTheme.success : AppTheme.warning).opacity(0.6), radius: 4)

                Text(hasAccessibility ? "Accessibility granted" : "Permission needed")
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(AppTheme.borderSubtle, lineWidth: 1)
                    }
            }
        }
    }
}
