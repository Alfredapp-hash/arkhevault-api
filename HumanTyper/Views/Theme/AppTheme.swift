import SwiftUI

enum AppTheme {
    // MARK: - Palette

    static let accent = Color(red: 0.45, green: 0.62, blue: 1.0)
    static let accentSecondary = Color(red: 0.36, green: 0.84, blue: 0.78)
    static let accentWarm = Color(red: 1.0, green: 0.72, blue: 0.45)

    static let surfaceElevated = Color(nsColor: .controlBackgroundColor).opacity(0.55)
    static let surfaceInset = Color.black.opacity(0.18)
    static let borderSubtle = Color.white.opacity(0.08)
    static let borderHighlight = Color.white.opacity(0.16)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.72)

    static let success = Color(red: 0.34, green: 0.84, blue: 0.55)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.32)
    static let danger = Color(red: 1.0, green: 0.42, blue: 0.45)

    // MARK: - Metrics

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Typography

    static func titleFont() -> Font { .system(size: 28, weight: .semibold, design: .rounded) }
    static func headlineFont() -> Font { .system(size: 13, weight: .semibold, design: .rounded) }
    static func bodyFont() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func captionFont() -> Font { .system(size: 11, weight: .medium, design: .rounded) }
    static func monoFont() -> Font { .system(size: 13, weight: .regular, design: .monospaced) }
    static func statFont() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
}

// MARK: - View Modifiers

struct PremiumCardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.lg
    var cornerRadius: CGFloat = AppTheme.Radius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [AppTheme.borderHighlight, AppTheme.borderSubtle],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
            }
    }
}

struct PremiumInsetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(AppTheme.surfaceInset)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func premiumCard(padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        modifier(PremiumCardStyle(padding: padding))
    }

    func premiumInset() -> some View {
        modifier(PremiumInsetStyle())
    }
}

// MARK: - Button Styles

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headlineFont())
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [AppTheme.accent, AppTheme.accentSecondary]
                                : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? AppTheme.accent.opacity(configuration.isPressed ? 0.1 : 0.35) : .clear,
                        radius: configuration.isPressed ? 4 : 12,
                        y: configuration.isPressed ? 2 : 6
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headlineFont())
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                            .strokeBorder(AppTheme.borderHighlight, lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct GhostActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.captionFont())
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background {
                Capsule()
                    .fill(configuration.isPressed ? Color.white.opacity(0.08) : Color.clear)
            }
    }
}
