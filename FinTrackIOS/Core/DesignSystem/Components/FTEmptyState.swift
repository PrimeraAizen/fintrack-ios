import SwiftUI

struct FTEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: FTSpacing.s4) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(FTColor.textTertiary)

            VStack(spacing: FTSpacing.s1) {
                Text(title)
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)

                Text(message)
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let title = actionTitle, let action {
                FTButton(title, size: .medium, action: action)
                    .fixedSize()
            }
        }
        .padding(FTSpacing.s6)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FTEmptyState(
        icon: "tray",
        title: "No transactions",
        message: "Tap the + button to add your first transaction.",
        actionTitle: "Add Transaction",
        action: {}
    )
}
