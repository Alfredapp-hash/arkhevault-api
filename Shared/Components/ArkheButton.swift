import SwiftUI

// MARK: - Arkhe Vault Branded Button
struct ArkheButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isDisabled: Bool = false
    var isLoading: Bool = false
    
    enum ButtonStyle {
        case primary, secondary, danger, outline, ghost
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.brandBody)
                    .fontWeight(.semibold)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled || isLoading ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .secondary, .danger: return .warmIvory
        case .outline, .ghost: return .forgeTeal
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .forgeTeal
        case .secondary: return .bronze
        case .danger: return .dangerRed
        case .outline: return Color.clear
        case .ghost: return Color.forgeTeal.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline: return .forgeTeal
        default: return Color.clear
        }
    }
}

// MARK: - Icon Button Variant
struct ArkheIconButton: View {
    let systemImage: String
    let action: () -> Void
    var style: ArkheButton.ButtonStyle = .primary
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(style == .outline ? .forgeTeal : .warmIvory)
                .frame(width: 36, height: 36)
                .background(style == .outline ? Color.clear : backgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style == .outline ? Color.forgeTeal : Color.clear, lineWidth: 2)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .forgeTeal
        case .secondary: return .bronze
        case .danger: return .dangerRed
        case .outline: return Color.clear
        case .ghost: return Color.forgeTeal.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ArkheButton(title: "Primary Action", style: .primary) {}
        ArkheButton(title: "Secondary Action", style: .secondary) {}
        ArkheButton(title: "Danger Action", style: .danger) {}
        ArkheButton(title: "Outline Action", style: .outline) {}
        ArkheButton(title: "Ghost Action", style: .ghost) {}
        ArkheButton(title: "Loading", style: .primary, isLoading: true) {}
        
        HStack(spacing: 12) {
            ArkheIconButton(systemImage: "plus", style: .primary) {}
            ArkheIconButton(systemImage: "heart", style: .secondary) {}
            ArkheIconButton(systemImage: "trash", style: .danger) {}
            ArkheIconButton(systemImage: "pencil", style: .outline) {}
        }
    }
    .padding()
    .frame(width: 300)
    .background(Color.deepCharcoal)
}