import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    let apiClient: APIClient

    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var error: APIError?

    private var fraction: Double {
        guard budget.spendingLimit > 0 else { return 0 }
        return min(1, NSDecimalNumber(decimal: budget.spent / budget.spendingLimit).doubleValue)
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: FTSpacing.s4) {
                    // Hero ring card
                    FTCard {
                        VStack(spacing: FTSpacing.s4) {
                            HStack {
                                Spacer()
                                FTProgressRing(value: budget.spent, total: budget.spendingLimit, lineWidth: 12)
                                    .frame(width: 180, height: 180)
                                    .overlay {
                                        VStack(spacing: 2) {
                                            Text(CurrencyFormatter.format(budget.spent, currency: "KZT"))
                                                .font(FTTypography.numericLG)
                                                .foregroundStyle(FTColor.textPrimary)
                                            Text("spent")
                                                .font(FTTypography.bodySM)
                                                .foregroundStyle(FTColor.textSecondary)
                                        }
                                    }
                                Spacer()
                            }

                            Divider().overlay(FTColor.border)

                            HStack(spacing: 0) {
                                statColumn(label: "Limit",     value: CurrencyFormatter.format(budget.spendingLimit, currency: "KZT"))
                                Divider().frame(height: 32)
                                statColumn(label: "Spent",     value: CurrencyFormatter.format(budget.spent, currency: "KZT"))
                                Divider().frame(height: 32)
                                statColumn(label: "Remaining", value: CurrencyFormatter.format(budget.remaining, currency: "KZT"))
                            }
                        }
                        .padding(FTSpacing.s4)
                    }
                    .padding(.horizontal, FTSpacing.s4)

                    if budget.exceeded {
                        FTErrorBanner(
                            message: "Over by \(CurrencyFormatter.format(budget.spent - budget.spendingLimit, currency: "KZT"))"
                        )
                        .padding(.horizontal, FTSpacing.s4)
                    }

                    // Recent transactions
                    VStack(alignment: .leading, spacing: FTSpacing.s3) {
                        Text("Transactions in this category")
                            .font(FTTypography.headingMD)
                            .foregroundStyle(FTColor.textPrimary)
                            .padding(.horizontal, FTSpacing.s4)

                        if isLoading && transactions.isEmpty {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if transactions.isEmpty {
                            FTEmptyState(
                                icon: "tray",
                                title: "No transactions",
                                message: "Transactions for this budget category will appear here."
                            )
                        } else {
                            FTCard {
                                ForEach(Array(transactions.enumerated()), id: \.element.id) { idx, tx in
                                    NavigationLink(destination: TransactionDetailView(transaction: tx, apiClient: apiClient)) {
                                        TransactionRow(transaction: tx, showDivider: idx < transactions.count - 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, FTSpacing.s4)
                        }
                    }
                }
                .padding(.vertical, FTSpacing.s4)
            }
        }
        .navigationTitle(budget.period.displayName + " Budget")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await loadTransactions() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await loadTransactions() }
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(FTTypography.bodySM)
                .foregroundStyle(FTColor.textSecondary)
            Text(value)
                .font(FTTypography.numericMD)
                .foregroundStyle(FTColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadTransactions() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            let filters = Endpoint.Transactions.Filters(categoryID: budget.categoryID, perPage: 50)
            let result = try await apiClient.sendPaginated(Endpoint.Transactions.list(filters: filters), as: Transaction.self)
            transactions = result.items
        } catch let e as APIError { error = e } catch { self.error = .network }
    }
}
