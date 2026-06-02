import SwiftUI

// MARK: - Arkhe Vault Brand System
struct BrandSystem {
    // Brand Identity
    static let appName = "Arkhe Vault"
    static let parentCompany = "Arkhe Holdings"
    static let tagline = "Protecting Data. Empowering Missions."
    static let version = "1.0.0"
    
    // Logo Configuration
    static let logoFileName = "arkhe_vault_logo" // Add your logo to Assets.xcassets
    static let logoFileNameDark = "arkhe_vault_logo_dark" // Optional dark mode variant
    static let logoFileNameCompact = "arkhe_vault_logo_compact" // Optional compact version
    static let parentLogoFileName = "arkhe_holdings_logo" // Parent company logo
}

// MARK: - Arkhe Vault Color System
extension Color {
    // Primary Brand Colors (Arkhe Holdings - Cyan/Teal Tech)
    static let arkheCyan = Color(red: 0.0, green: 0.85, blue: 0.75) // #00D9C0
    static let arkheCyanLight = Color(red: 0.2, green: 0.90, blue: 0.82) // #33E6D1
    static let arkheCyanDark = Color(red: 0.0, green: 0.65, blue: 0.57) // #00A691
    
    // Tech Blue - Secondary
    static let techBlue = Color(red: 0.0, green: 0.66, blue: 0.91) // #00A8E8
    static let techBlueLight = Color(red: 0.27, green: 0.76, blue: 0.95) // #45C2F3
    static let techBlueDark = Color(red: 0.0, green: 0.50, blue: 0.72) // #007FB8
    
    // Deep Space - Background
    static let deepSpace = Color(red: 0.04, green: 0.06, blue: 0.11) // #0A0F1C
    static let deepSpaceLight = Color(red: 0.08, green: 0.11, blue: 0.18) // #141C2E
    static let deepSpaceDark = Color(red: 0.02, green: 0.03, blue: 0.06) // #050810
    
    // Shield Silver - Accents
    static let shieldSilver = Color(red: 0.75, green: 0.77, blue: 0.81) // #BFC3CF
    static let shieldSilverLight = Color(red: 0.88, green: 0.89, blue: 0.91) // #E0E3E8
    static let shieldSilverDark = Color(red: 0.56, green: 0.58, blue: 0.62) // #8F949E
    
    // Cyber Glow - Highlights
    static let cyberGlow = Color(red: 0.0, green: 0.96, blue: 0.83) // #00F5D4
    static let cyberGlowSoft = Color(red: 0.0, green: 0.96, blue: 0.83).opacity(0.5)
    
    // Legacy aliases (for backward compatibility during transition)
    static let forgeTeal = arkheCyan
    static let forgeTealLight = arkheCyanLight
    static let forgeTealDark = arkheCyanDark
    static let bronze = shieldSilver
    static let bronzeLight = shieldSilverLight
    static let bronzeDark = shieldSilverDark
    static let warmIvory = shieldSilverLight
    static let deepCharcoal = deepSpace
    static let darkCharcoal = deepSpaceDark
    
    // Status Colors (Tech-Security Theme)
    static let successGreen = Color(red: 0.0, green: 0.90, blue: 0.46) // #00E676
    static let warningGold = Color(red: 1.0, green: 0.72, blue: 0.30) // #FFB74D
    static let dangerRed = Color(red: 1.0, green: 0.20, blue: 0.40) // #FF3366
    static let infoBlue = techBlue
    
    // Security Status Colors
    static let securityGreen = Color(red: 0.0, green: 0.90, blue: 0.46) // #00E676
    static let securityRed = Color(red: 1.0, green: 0.20, blue: 0.40) // #FF3366
    static let securityYellow = Color(red: 1.0, green: 0.72, blue: 0.30) // #FFB74D
    
    // Risk Level Colors (Updated for tech theme)
    static let riskLow = Color(red: 0.0, green: 0.90, blue: 0.46) // #00E676
    static let riskMedium = Color(red: 1.0, green: 0.72, blue: 0.30) // #FFB74D
    static let riskHigh = Color(red: 1.0, green: 0.46, blue: 0.0) // #FF7500
    static let riskCritical = Color(red: 1.0, green: 0.20, blue: 0.40) // #FF3366
    
    // Utility Colors
    static let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95) // #EAEDF2
    static let textSecondary = Color(red: 0.75, green: 0.77, blue: 0.81) // #BFC3CF
    static let textMuted = Color(red: 0.56, green: 0.58, blue: 0.62) // #8F949E
    
    // Brand Border Colors
    static let brandBorder = Color(red: 0.20, green: 0.25, blue: 0.35) // #334059
    static let brandBorderLight = Color(red: 0.30, green: 0.35, blue: 0.45) // #4D5973
    static let brandBorderGlow = arkheCyan.opacity(0.3)
}

// MARK: - Forged In Fire Typography
extension Font {
    static let brandTitle = Font.system(size: 28, weight: .bold, design: .serif)
    static let brandHeading = Font.system(size: 22, weight: .semibold, design: .serif)
    static let brandSubheading = Font.system(size: 18, weight: .medium, design: .serif)
    static let brandBody = Font.system(size: 14, weight: .regular, design: .default)
    static let brandBodyBold = Font.system(size: 14, weight: .semibold, design: .default)
    static let brandCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let brandSmall = Font.system(size: 10, weight: .regular, design: .default)
    static let brandTiny = Font.system(size: 9, weight: .regular, design: .default)
    
    // Logo-specific typography
    static let logoText = Font.system(size: 20, weight: .bold, design: .default)
    
    // Tech typography
    static let techTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let techHeading = Font.system(size: 22, weight: .semibold, design: .default)
    static let techSubheading = Font.system(size: 18, weight: .medium, design: .default)
    static let techBody = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let techCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
}
    static let taglineText = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Forged In Fire Gradients
extension LinearGradient {
    static let forgeGradient = LinearGradient(
        colors: [.forgeTeal, .forgeTealLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let bronzeGradient = LinearGradient(
        colors: [.bronze, .bronzeLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [.warmIvory, .cream],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Forged In Fire Shadows
extension View {
    func forgeShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func forgeGlow() -> some View {
        self.shadow(color: Color.forgeTeal.opacity(0.2), radius: 20, x: 0, y: 0)
    }
    
    func bronzeGlow() -> some View {
        self.shadow(color: Color.bronze.opacity(0.15), radius: 20, x: 0, y: 0)
    }
}