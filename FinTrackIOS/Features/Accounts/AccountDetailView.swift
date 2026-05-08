import SwiftUI

struct AccountDetailView: View {
    let account: Account
    let apiClient: APIClient

    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var error: APIError?
    @State private var showTransfer = false

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: FTSpacing.s4) {
                    // Hero card
                    FTCard {
                        VStack(alignment: .leading, spacing: FTSpacing.s3) {
                            HStack {
                                Text("Balance")
                                    .font(FTTypography.label)
                                    .foregroundStyle(FTColor.textSecondary)
                                Spacer()
                                Text(account.type.displayName)
                                    .font(FTTypography.label)
                                    .foregroundStyle(FTColor.primary)
                                    .padding(.horizontal, FTSpacing.s2)
                                    .padding(.vertical, 3)
                                    .background(FTColor.primarySoft)
                                    .clipShape(Capsule())
                            }

                            Text(CurrencyFormatter.format(account.balance, currency: account.currency))
                                .font(FTTypography.displayLG)
                                .foregroundStyle(FTColor.textPrimary)

                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(FTColor.textTertiary)
                                    .font(.system(size: 13))
                                Text("Since \(DateFormatter.display.string(from: account.createdAt))")
                                    .font(FTTypography.bodySM)
                                    .foregroundStyle(FTColor.textSecondary)
                            }
                        }
                        .padding(FTSpacing.s4)
                    }
                    .padding(.horizontal, FTSpacing.s4)

                    FTButton("Transfer", style: .secondary, size: .medium) {
                        showTransfer = true
                    }
                    .padding(.horizontal, FTSpacing.s4)

                    // Transactions section
                    VStack(alignment: .leading, spacing: FTSpacing.s3) {
                        Text("Transactions")
                            .font(FTTypography.headingMD)
                            .foregroundStyle(FTColor.textPrimary)
                            .padding(.horizontal, FTSpacing.s4)

                        if isLoading && transactions.isEmpty {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if transactions.isEmpty {
                            FTEmptyState(
                                icon: "list.bullet",
                                title: "No transactions",
                                message: "Transactions for this account will appear here."
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
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTransfer) {
            // Uses TransferView with this account pre-selected as from
        }
        .overlay(alignment: .top) {
            if let error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await loadTransactions() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await loadTransactions() }
    }

    private func loadTransactions() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let filters = Endpoint.Transactions.Filters(accountID: account.id, perPage: 50)
            let result = try await apiClient.sendPaginated(Endpoint.Transactions.list(filters: filters), as: Transaction.self)
            transactions = result.items
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(account: .preview, apiClient: APIClient.fromPlist())
    }
}
