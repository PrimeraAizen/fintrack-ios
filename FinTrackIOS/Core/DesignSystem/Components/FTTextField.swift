import SwiftUI

struct FTTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil

    @FocusState private var focused: Bool
    @State private var showSecret = false

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.s1) {
            Text(label)
                .font(FTTypography.label)
                .foregroundStyle(FTColor.textSecondary)

            HStack {
                Group {
                    if isSecure && !showSecret {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                    }
                }
                .font(FTTypography.bodyLG)
                .foregroundStyle(FTColor.textPrimary)
                .focused($focused)
                .frame(height: 48)

                if isSecure {
                    Button {
                        showSecret.toggle()
                    } label: {
                        Image(systemName: showSecret ? "eye.slash" : "eye")
                            .foregroundStyle(FTColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FTSpacing.s4)
            .background(FTColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FTRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.md)
                    .strokeBorder(
                        focused ? FTColor.primary : (errorMessage != nil ? FTColor.danger : FTColor.border),
                        lineWidth: focused ? 2 : 1
                    )
            )
            .animation(.easeOut(duration: 0.15), value: focused)

            if let error = errorMessage {
                Text(error)
                    .font(FTTypography.bodySM)
                    .foregroundStyle(FTColor.danger)
            }
        }
    }
}

#Preview {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = ""
    @Previewable @State var text3 = "bad@value"

    VStack(spacing: FTSpacing.s4) {
        FTTextField(label: "Email", placeholder: "you@example.com", text: $text1, keyboardType: .emailAddress)
        FTTextField(label: "Password", placeholder: "••••••••", text: $text2, isSecure: true)
        FTTextField(label: "Amount", placeholder: "0.00", text: $text3, errorMessage: "Invalid amount")
    }
    .padding()
}
