import SwiftUI

// MARK: - Forged In Fire Logo Component
struct ForgeLogo: View {
    var size: LogoSize = .medium
    var style: LogoStyle = .full
    var showTagline: Bool = false
    
    var body: some View {
        Group {
            if style == .iconOnly {
                IconOnlyLogo(size: size)
            } else {
                FullLogo(size: size, showTagline: showTagline)
            }
        }
    }
}

// MARK: - Logo Sizes
enum LogoSize {
    case extraSmall  // 24pt
    case small       // 32pt
    case compact     // 40pt
    case medium      // 48pt
    case large       // 64pt
    case extraLarge  // 96pt
    
    var iconSize: CGFloat {
        switch self {
        case .extraSmall: return 24
        case .small: return 32
        case .compact: return 40
        case .medium: return 48
        case .large: return 64
        case .extraLarge: return 96
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .extraSmall: return 12
        case .small: return 14
        case .compact: return 16
        case .medium: return 18
        case .large: return 24
        case .extraLarge: return 32
        }
    }
}

// MARK: - Logo Styles
enum LogoStyle {
    case full      // Icon + Text
    case iconOnly  // Icon only
    case textOnly  // Text only
    case compact   // Compact version
}

// MARK: - Full Logo View
struct FullLogo: View {
    var size: LogoSize
    var showTagline: Bool
    
    var body: some View {
        HStack(spacing: size == .compact ? 8 : 12) {
            // Icon
            LogoIcon(size: size.iconSize)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(BrandSystem.appName)
                    .font(.system(size: size.fontSize, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                    .tracking(size == .compact ? 0.5 : 0)
                
                if showTagline {
                    Text(BrandSystem.tagline)
                        .font(.system(size: size.fontSize * 0.6, weight: .medium, design: .default))
                        .foregroundColor(.textSecondary)
                        .tracking(0.5)
                }
            }
        }
    }
}

// MARK: - Icon Only Logo
struct IconOnlyLogo: View {
    var size: LogoSize
    
    var body: some View {
        LogoIcon(size: size.iconSize)
    }
}

// MARK: - Logo Icon
struct LogoIcon: View {
    var size: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(
                    LinearGradient(
                        colors: [.forgeTeal, .forgeTealLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Flame/Symbol Icon
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.warmIvory)
        }
        .shadow(color: Color.forgeTeal.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Brand Header Component
struct BrandHeader: View {
    var title: String
    var subtitle: String?
    var showLogo: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            if showLogo {
                ForgeLogo(size: .medium, style: .iconOnly)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brandTitle)
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Brand Footer Component
struct BrandFooter: View {
    var showLogo: Bool = true
    var showVersion: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            if showLogo {
                ForgeLogo(size: .compact, style: .iconOnly)
            }
            
            Text(BrandSystem.appName)
                .font(.brandBodyBold)
                .foregroundColor(.textSecondary)
            
            if showVersion {
                Text("Version \(BrandSystem.version)")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
            }
            
            Text(BrandSystem.tagline)
                .font(.brandCaption)
                .foregroundColor(.textMuted)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.footerCharcoal)
    }
}

// MARK: - Brand Card Component
struct BrandCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let showLogo: Bool
    let content: Content
    
    init(title: String, subtitle: String? = nil, showLogo: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.showLogo = showLogo
        self.content = content()
    }
    
    var body: some View {
        ForgeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with logo
                HStack {
                    if showLogo {
                        ForgeLogo(size: .small, style: .iconOnly)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.brandHeading)
                            .foregroundColor(.textPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Content
                content
            }
        }
    }
}

// MARK: - Brand Section Header
struct BrandSectionHeader: View {
    let title: String
    let subtitle: String?
    var showDivider: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.brandSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.forgeTeal)
                    .tracking(1.5)
                
                Spacer()
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            
            if showDivider {
                Rectangle()
                    .fill(Color.brandBorder)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Brand Button Component
struct BrandButton: View {
    let title: String
    var icon: String?
    var style: ButtonStyle = .primary
    var isFullWidth: Bool = false
    var action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case danger
        case success
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.brandCaption)
                }
                
                Text(title)
                    .font(.brandBodyBold)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(buttonBackground)
            .foregroundColor(buttonForeground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(buttonBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackground: Color {
        switch style {
        case .primary:
            return Color.forgeTeal
        case .secondary:
            return Color.bronze
        case .outline:
            return Color.clear
        case .danger:
            return Color.dangerRed
        case .success:
            return Color.successGreen
        }
    }
    
    private var buttonForeground: Color {
        switch style {
        case .primary, .secondary, .danger, .success:
            return .warmIvory
        case .outline:
            return .textPrimary
        }
    }
    
    private var buttonBorder: Color {
        switch style {
        case .primary, .secondary, .danger, .success:
            return Color.clear
        case .outline:
            return .brandBorder
        }
    }
}

// MARK: - Brand Badge Component
struct BrandBadge: View {
    let text: String
    var color: Color = .forgeTeal
    var style: BadgeStyle = .filled
    
    enum BadgeStyle {
        case filled
        case outline
        case subtle
    }
    
    var body: some View {
        Text(text)
            .font(.brandTiny)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackground)
            .foregroundColor(badgeForeground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(badgeBorder, lineWidth: 1)
            )
    }
    
    private var badgeBackground: Color {
        switch style {
        case .filled:
            return color
        case .outline:
            return Color.clear
        case .subtle:
            return color.opacity(0.15)
        }
    }
    
    private var badgeForeground: Color {
        switch style {
        case .filled:
            return .warmIvory
        case .outline:
            return color
        case .subtle:
            return color
        }
    }
    
    private var badgeBorder: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outline:
            return color
        case .subtle:
            return Color.clear
        }
    }
}

// MARK: - Preview
#Preview("Logo Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForgeLogo(size: .extraSmall)
            ForgeLogo(size: .small)
            ForgeLogo(size: .compact)
            ForgeLogo(size: .medium)
        }
        
        HStack(spacing: 20) {
            ForgeLogo(size: .large)
            ForgeLogo(size: .extraLarge)
        }
    }
    .padding()
    .background(Color.deepCharcoal)
}

#Preview("Logo Styles") {
    VStack(spacing: 20) {
        ForgeLogo(size: .medium, style: .full, showTagline: true)
        ForgeLogo(size: .medium, style: .iconOnly)
    }
    .padding()
    .background(Color.deepCharcoal)
}

#Preview("Brand Components") {
    VStack(spacing: 20) {
        BrandHeader(title: "Dashboard", subtitle: "Overview of your organization", showLogo: true)
        
        BrandSectionHeader(title: "Recent Activity", subtitle: "Latest updates", showDivider: true)
        
        HStack(spacing: 12) {
            BrandBadge(text: "Active", color: .successGreen, style: .filled)
            BrandBadge(text: "Pending", color: .warningGold, style: .outline)
            BrandBadge(text: "Urgent", color: .dangerRed, style: .subtle)
        }
    }
    .padding()
    .background(Color.deepCharcoal)
}