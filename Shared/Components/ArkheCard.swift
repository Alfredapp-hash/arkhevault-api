import SwiftUI

// MARK: - Arkhe Vault Branded Card
struct ArkheCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .lightCharcoal
    var cornerRadius: CGFloat = 12
    var shadow: Bool = true
    var border: Bool = true
    var borderColor: Color = .lightCharcoal
    
    init(backgroundColor: Color = .lightCharcoal, 
         cornerRadius: CGFloat = 12,
         shadow: Bool = true,
         border: Bool = true,
         borderColor: Color = .lightCharcoal,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.border = border
        self.borderColor = borderColor
    }
    
    var body: some View {
        content
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(border ? borderColor : Color.clear, lineWidth: 1)
            )
            .if(shadow) { view in
                view.forgeShadow()
            }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let status: Status
    
    enum Status {
        case active, warning, danger, info, success, neutral
    }
    
    var body: some View {
        Text(text)
            .font(.brandSmall)
            .fontWeight(.semibold)
            .foregroundColor(.warmIvory)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return .forgeTeal
        case .warning: return .warningGold
        case .danger: return .dangerRed
        case .info: return .infoBlue
        case .success: return .successGreen
        case .neutral: return .warmStone
        }
    }
}

// MARK: - Risk Level Indicator
struct RiskLevelIndicator: View {
    let level: RiskLevel
    var showLabel: Bool = true
    
    enum RiskLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(riskColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            
            if showLabel {
                Text(levelText)
                    .font(.brandCaption)
                    .fontWeight(.medium)
                    .foregroundColor(riskColor)
            }
        }
    }
    
    private var riskColor: Color {
        switch level {
        case .low: return .riskLow
        case .medium: return .riskMedium
        case .high: return .riskHigh
        case .critical: return .riskCritical
        }
    }
    
    private var levelText: String {
        switch level {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .forgeTeal
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brandSmall)
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var action: (() -> Void)?
    var actionTitle: String = "See All"
    
    var body: some View {
        HStack(alignment: .center) {
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
            
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.brandCaption)
                        .foregroundColor(.forgeTeal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Conditional View Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ArkheCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Text("Card content goes here with the Arkhe Vault branding applied.")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                
                HStack {
                    StatusBadge(text: "Active", status: .active)
                    StatusBadge(text: "Warning", status: .warning)
                    StatusBadge(text: "Danger", status: .danger)
                }
            }
        }
        
        ArkheCard(backgroundColor: .deepCharcoal) {
            VStack(spacing: 12) {
                RiskLevelIndicator(level: .low)
                RiskLevelIndicator(level: .medium)
                RiskLevelIndicator(level: .high)
                RiskLevelIndicator(level: .critical)
                
                InfoRow(icon: "person.fill", title: "Client", value: "Jane Doe")
                InfoRow(icon: "phone.fill", title: "Phone", value: "(555) 123-4567")
                InfoRow(icon: "house.fill", title: "Housing", value: "Stable", iconColor: .successGreen)
            }
        }
        
        SectionHeader(
            title: "Recent Activity",
            subtitle: "Last 7 days",
            action: { print("See all clicked") }
        )
    }
    .padding()
    .frame(maxWidth: 500)
    .background(Color.deepCharcoal)
}