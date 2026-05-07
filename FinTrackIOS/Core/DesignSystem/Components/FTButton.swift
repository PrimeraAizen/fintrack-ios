import SwiftUI

enum FTButtonStyle { case primary, secondary, ghost, destructive }
enum FTButtonSize  { case large, medium, small }

struct FTButton: View {
    let title: String
    let style: FTButtonStyle
    let size: FTButtonSize
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: FTButtonStyle = .primary,
        size: FTButtonSize = .large,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(fgColor)
                } else {
                    Text(title)
                        .font(size == .small ? FTTypography.label : FTTypography.headingMD)
                }
            }
            .frame(maxWidth: size == .large ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, size == .small ? FTSpacing.s3 : FTSpacing.s5)
        }
        .buttonStyle(_FTButtonStyle(style: style, fgColor: fgColor, bgColor: bgColor, borderColor: borderColor))
        .disabled(isLoading)
    }

    private var height: CGFloat {
        switch size {
        case .large:  52
        case .medium: 44
        case .small:  32
        }
    }

    private var fgColor: Color {
        switch style {
        case .primary:     .white
        case .secondary:   FTColor.primary
        case .ghost:       FTColor.primary
        case .destructive: .white
        }
    }

    private var bgColor: Color {
        switch style {
        case .primary:     FTColor.primary
        case .secondary:   FTColor.primarySoft
        case .ghost:       .clear
        case .destructive: FTColor.danger
        }
    }

    private var borderColor: Color? {
        style == .ghost ? FTColor.border : nil
    }
}

private struct _FTButtonStyle: ButtonStyle {
    let style: FTButtonStyle
    let fgColor: Color
    let bgColor: Color
    let borderColor: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(fgColor)
            .background(bgColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let border = borderColor {
                        Capsule().strokeBorder(border, lineWidth: 1)
                    }
                }
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: FTSpacing.s4) {
        FTButton("Continue") {}
        FTButton("Add Account", style: .secondary, size: .medium) {}
        FTButton("Cancel", style: .ghost, size: .medium) {}
        FTButton("Delete", style: .destructive, size: .small) {}
        FTButton("Loading", isLoading: true) {}
    }
    .padding()
}
