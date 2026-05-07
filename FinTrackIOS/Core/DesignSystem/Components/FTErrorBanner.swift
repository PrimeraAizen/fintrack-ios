import SwiftUI

struct FTErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: FTSpacing.s3) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(FTColor.danger)

            Text(message)
                .font(FTTypography.bodyMD)
                .foregroundStyle(FTColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let retry = retryAction {
                Button(action: retry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(FTColor.danger)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FTSpacing.s4)
        .padding(.vertical, FTSpacing.s3)
        .background(FTColor.danger.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.md))
    }
}

#Preview {
    VStack(spacing: FTSpacing.s3) {
        FTErrorBanner(message: "Something went wrong. Please try again.")
        FTErrorBanner(message: "Unable to load transactions.", retryAction: {})
    }
    .padding()
}
