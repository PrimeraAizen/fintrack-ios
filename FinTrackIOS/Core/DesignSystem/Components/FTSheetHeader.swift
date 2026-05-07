import SwiftUI

struct FTSheetHeader: View {
    let title: String
    let onCancel: (() -> Void)?
    let onSave: (() -> Void)?
    var saveLabel: String = "Save"
    var isSaveDisabled: Bool = false

    var body: some View {
        VStack(spacing: FTSpacing.s2) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(FTColor.border)
                .frame(width: 36, height: 5)
                .padding(.top, FTSpacing.s2)

            HStack {
                if let cancel = onCancel {
                    Button("Cancel", action: cancel)
                        .font(FTTypography.bodyLG)
                        .foregroundStyle(FTColor.textSecondary)
                } else {
                    Spacer().frame(width: 60)
                }

                Spacer()

                Text(title)
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)

                Spacer()

                if let save = onSave {
                    Button(saveLabel, action: save)
                        .font(FTTypography.headingMD)
                        .foregroundStyle(isSaveDisabled ? FTColor.textTertiary : FTColor.primary)
                        .disabled(isSaveDisabled)
                } else {
                    Spacer().frame(width: 60)
                }
            }
            .padding(.horizontal, FTSpacing.s4)
            .frame(height: 44)

            Divider().overlay(FTColor.border)
        }
    }
}

#Preview {
    FTSheetHeader(title: "Add Transaction", onCancel: {}, onSave: {})
}
