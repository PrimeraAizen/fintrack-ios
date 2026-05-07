import SwiftUI

struct FTCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(FTColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    FTCard {
        VStack(alignment: .leading, spacing: FTSpacing.s2) {
            Text("Card Title").font(FTTypography.headingMD)
            Text("Some card content goes here.").font(FTTypography.bodyMD).foregroundStyle(FTColor.textSecondary)
        }
        .padding(FTSpacing.s4)
    }
    .padding()
}
