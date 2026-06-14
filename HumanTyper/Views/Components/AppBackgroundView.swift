import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppTheme.accent.opacity(colorScheme == .dark ? 0.18 : 0.12), .clear],
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )

            RadialGradient(
                colors: [AppTheme.accentSecondary.opacity(colorScheme == .dark ? 0.14 : 0.10), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 380
            )

            // Subtle noise-like grid
            Canvas { context, size in
                let step: CGFloat = 28
                var path = Path()
                for x in stride(from: 0, through: size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(colorScheme == .dark ? 0.02 : 0.04)), lineWidth: 0.5)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.07, green: 0.08, blue: 0.11),
                Color(red: 0.10, green: 0.11, blue: 0.15),
                Color(red: 0.08, green: 0.10, blue: 0.13)
            ]
        }
        return [
            Color(red: 0.94, green: 0.95, blue: 0.98),
            Color(red: 0.90, green: 0.93, blue: 0.97),
            Color(red: 0.92, green: 0.94, blue: 0.98)
        ]
    }
}
