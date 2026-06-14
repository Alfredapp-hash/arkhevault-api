import SwiftUI

struct PermissionsChecklistView: View {
    let hasAccessibility: Bool
    let layoutName: String
    let targetAppName: String?
    let dryRun: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Pre-flight checklist")
                .font(AppTheme.headlineFont())

            checklistRow("Accessibility granted", hasAccessibility)
            checklistRow("Keyboard layout: \(layoutName)", true)
            checklistRow("Target app: \(targetAppName ?? "Any focused app")", targetAppName != nil)
            checklistRow("Dry run mode", dryRun, optional: true)
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .fill(Color.white.opacity(0.03))
        }
    }

    private func checklistRow(_ title: String, _ ok: Bool, optional: Bool = false) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: ok ? "checkmark.circle.fill" : (optional ? "circle" : "exclamationmark.circle.fill"))
                .foregroundStyle(ok ? AppTheme.success : (optional ? AppTheme.textTertiary : AppTheme.warning))
                .font(.system(size: 12))
            Text(title)
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
