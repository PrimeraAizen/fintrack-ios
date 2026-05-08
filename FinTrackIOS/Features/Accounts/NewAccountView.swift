import SwiftUI

struct NewAccountView: View {
    let onSave: (String, AccountType, String, Decimal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: AccountType = .card
    @State private var currency = "KZT"
    @State private var balanceText = "0"
    @State private var nameError: String?

    private let currencies = ["KZT", "USD", "EUR"]

    var balance: Decimal {
        Decimal(string: balanceText) ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FTSpacing.s5) {
                        FTTextField(label: "Account name", placeholder: "e.g. Main Card",
                                    text: $name, errorMessage: nameError)

                        VStack(alignment: .leading, spacing: FTSpacing.s2) {
                            Text("Type")
                                .font(FTTypography.label)
                                .foregroundStyle(FTColor.textSecondary)

                            Picker("Type", selection: $type) {
                                ForEach(AccountType.creationOptions, id: \.self) { t in
                                    Text(t.displayName).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: FTSpacing.s2) {
                            Text("Currency")
                                .font(FTTypography.label)
                                .foregroundStyle(FTColor.textSecondary)

                            Picker("Currency", selection: $currency) {
                                ForEach(currencies, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FTTextField(label: "Initial balance", placeholder: "0",
                                    text: $balanceText, keyboardType: .decimalPad)
                    }
                    .padding(FTSpacing.s4)
                }

                VStack {
                    Spacer()
                    FTButton("Create account") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                            nameError = "Account name is required"
                            return
                        }
                        onSave(name, type, currency, balance)
                        dismiss()
                    }
                    .padding(.horizontal, FTSpacing.s4)
                    .padding(.bottom, FTSpacing.s8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("New Account").font(FTTypography.headingMD)
                }
            }
        }
    }
}

#Preview {
    NewAccountView { _, _, _, _ in }
}
