import SwiftUI

struct TransferView: View {
    @Environment(AppEnvironment.self) private var env
    let accounts: [Account]
    var onComplete: (() -> Void)? = nil

    var body: some View {
        _TransferBody(apiClient: env.apiClient, rateCache: env.rateCache, accounts: accounts, onComplete: onComplete)
    }
}

private struct _TransferBody: View {
    @State private var vm: TransferViewModel
    @Environment(\.dismiss) private var dismiss
    let onComplete: (() -> Void)?

    init(apiClient: APIClient, rateCache: ExchangeRateCache, accounts: [Account], onComplete: (() -> Void)?) {
        _vm = State(wrappedValue: TransferViewModel(apiClient: apiClient, rateCache: rateCache, accounts: accounts))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FTSpacing.s5) {
                        // From account
                        accountSelector(
                            label: "From",
                            account: vm.fromAccount,
                            excludeID: vm.toAccount?.id
                        ) { vm.fromAccount = $0 }

                        // Arrow
                        Image(systemName: "arrow.down")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(FTColor.primary)

                        // To account
                        accountSelector(
                            label: "To",
                            account: vm.toAccount,
                            excludeID: vm.fromAccount?.id
                        ) { vm.toAccount = $0 }

                        // Amount
                        amountField

                        // Exchange rate
                        if vm.currenciesDiffer {
                            exchangeRateCard
                        }

                        // Note
                        FTCard {
                            TextField("Add a note (optional)", text: $vm.note)
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textPrimary)
                                .padding(.horizontal, FTSpacing.s4)
                                .frame(minHeight: 52)
                        }
                        .padding(.horizontal, FTSpacing.s4)

                        if let error = vm.error {
                            FTErrorBanner(message: error.userMessage)
                                .padding(.horizontal, FTSpacing.s4)
                        }
                    }
                    .padding(.vertical, FTSpacing.s4)
                }

                VStack {
                    Spacer()
                    FTButton("Confirm transfer",
                             isLoading: vm.isLoading,
                             action: {
                        Task {
                            if await vm.submit() {
                                onComplete?()
                                dismiss()
                            }
                        }
                    })
                    .padding(.horizontal, FTSpacing.s4)
                    .padding(.bottom, FTSpacing.s8)
                    .disabled(!vm.isValid)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Transfer money").font(FTTypography.headingMD)
                }
            }
            .onChange(of: vm.fromAccount?.id) { _, _ in Task { await vm.refreshRate() } }
            .onChange(of: vm.toAccount?.id)   { _, _ in Task { await vm.refreshRate() } }
            .task { await vm.refreshRate() }
        }
    }

    // MARK: - Account Selector Card

    private func accountSelector(
        label: String,
        account: Account?,
        excludeID: UUID?,
        onSelect: @escaping (Account) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: FTSpacing.s1) {
            Text(label)
                .font(FTTypography.label)
                .foregroundStyle(FTColor.textSecondary)
                .padding(.horizontal, FTSpacing.s4)

            Menu {
                ForEach(vm.accounts.filter { $0.id != excludeID }) { acc in
                    Button {
                        onSelect(acc)
                    } label: {
                        Label(acc.name, systemImage: acc.type.iconName)
                    }
                }
            } label: {
                FTCard {
                    HStack(spacing: FTSpacing.s3) {
                        if let acc = account {
                            Image(systemName: acc.type.iconName)
                                .font(.system(size: 20))
                                .foregroundStyle(FTColor.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(acc.name)
                                    .font(FTTypography.headingMD)
                                    .foregroundStyle(FTColor.textPrimary)
                                Text(CurrencyFormatter.format(acc.balance, currency: acc.currency))
                                    .font(FTTypography.bodySM)
                                    .foregroundStyle(FTColor.textSecondary)
                            }
                        } else {
                            Text("Select account")
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(FTColor.textTertiary)
                    }
                    .padding(FTSpacing.s4)
                }
            }
            .padding(.horizontal, FTSpacing.s4)
        }
    }

    // MARK: - Amount Field

    private var amountField: some View {
        VStack(spacing: FTSpacing.s1) {
            HStack(alignment: .center, spacing: FTSpacing.s1) {
                Text(CurrencyFormatter.symbol(for: vm.fromAccount?.currency ?? "KZT"))
                    .font(FTTypography.displayLG)
                    .foregroundStyle(FTColor.textTertiary)
                TextField("0", text: $vm.amountText)
                    .font(FTTypography.displayLG)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(FTColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FTSpacing.s4)

            if let amountError = vm.amountError {
                Text(amountError)
                    .font(FTTypography.bodySM)
                    .foregroundStyle(FTColor.danger)
            }
        }
    }

    // MARK: - Exchange Rate Card

    private var exchangeRateCard: some View {
        FTCard {
            VStack(alignment: .leading, spacing: FTSpacing.s2) {
                if vm.isFetchingRate {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("Fetching rate…")
                            .font(FTTypography.bodySM)
                            .foregroundStyle(FTColor.textSecondary)
                    }
                } else if let rate = vm.exchangeRate {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exchange rate")
                                .font(FTTypography.label)
                                .foregroundStyle(FTColor.textSecondary)
                            Text("1 \(rate.from) = \(NSDecimalNumber(decimal: rate.rate).stringValue) \(rate.to)")
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textPrimary)
                        }
                        Spacer()
                        Text(RelativeTimeFormatter.rateCaption(updatedAt: rate.cachedAt))
                            .font(FTTypography.bodySM)
                            .foregroundStyle(FTColor.textTertiary)
                    }

                    if let converted = vm.convertedAmount, vm.amount > 0 {
                        Divider().overlay(FTColor.border)
                        HStack {
                            Text("You'll receive")
                                .font(FTTypography.label)
                                .foregroundStyle(FTColor.textSecondary)
                            Spacer()
                            Text(CurrencyFormatter.format(converted, currency: vm.toAccount?.currency ?? ""))
                                .font(FTTypography.numericMD)
                                .foregroundStyle(FTColor.textPrimary)
                        }
                    }
                }
            }
            .padding(FTSpacing.s4)
        }
        .padding(.horizontal, FTSpacing.s4)
    }
}

#Preview {
    TransferView(accounts: [.preview])
        .environment(AppEnvironment())
}
