import SwiftUI

struct FTListRow<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing
    let title: String
    let subtitle: String?
    var showDivider: Bool = true

    init(
        title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showDivider = showDivider
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: FTSpacing.s3) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textPrimary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(FTTypography.bodySM)
                            .foregroundStyle(FTColor.textSecondary)
                    }
                }

                Spacer()

                trailing
            }
            .frame(minHeight: 56)
            .padding(.horizontal, FTSpacing.s4)

            if showDivider {
                Divider()
                    .overlay(FTColor.border)
                    .padding(.leading, FTSpacing.s4)
            }
        }
    }
}

extension FTListRow where Leading == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: title, subtitle: subtitle, showDivider: showDivider, leading: { EmptyView() }, trailing: trailing)
    }
}

extension FTListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(title: title, subtitle: subtitle, showDivider: showDivider, leading: leading, trailing: { EmptyView() })
    }
}

extension FTListRow where Leading == EmptyView, Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, showDivider: Bool = true) {
        self.init(title: title, subtitle: subtitle, showDivider: showDivider, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

#Preview {
    FTCard {
        VStack(spacing: 0) {
            FTListRow(title: "Groceries", subtitle: "May 8") {
                Circle().fill(FTColor.catPeach).frame(width: 36, height: 36)
            } trailing: {
                Text("–$42.00").font(FTTypography.numericMD).foregroundStyle(FTColor.textPrimary)
            }

            FTListRow(title: "Salary", showDivider: false, trailing: {
                Text("+$3,000").font(FTTypography.numericMD).foregroundStyle(FTColor.income)
            })
        }
    }
    .padding()
}
