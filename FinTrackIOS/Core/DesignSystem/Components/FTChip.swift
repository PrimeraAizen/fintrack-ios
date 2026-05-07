import SwiftUI

struct FTChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    init(_ title: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FTTypography.label)
                .foregroundStyle(isActive ? FTColor.primary : FTColor.textSecondary)
                .padding(.horizontal, FTSpacing.s3)
                .frame(height: 28)
                .background(isActive ? FTColor.primarySoft : FTColor.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(isActive ? FTColor.primary.opacity(0.4) : FTColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

#Preview {
    HStack(spacing: FTSpacing.s2) {
        FTChip("All", isActive: true) {}
        FTChip("Income") {}
        FTChip("Expenses") {}
    }
    .padding()
}
