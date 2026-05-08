import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _HomeBody(apiClient: env.apiClient, authService: env.authService)
    }
}

private struct _HomeBody: View {
    @State private var vm: HomeViewModel
    let apiClient: APIClient
    let authService: AuthService

    init(apiClient: APIClient, authService: AuthService) {
        _vm = State(wrappedValue: HomeViewModel(apiClient: apiClient))
        self.apiClient = apiClient
        self.authService = authService
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: FTSpacing.s5) {
                    // Header
                    headerView

                    if vm.isLoading && vm.accounts.isEmpty {
                        ProgressView().padding(.top, FTSpacing.s12)
                    } else {
                        // Balance hero
                        balanceHeroCard

                        // Quick stats
                        quickStatsRow

                        // Recent transactions
                        recentTransactionsSection
                    }
                }
                .padding(.horizontal, FTSpacing.s4)
                .padding(.vertical, FTSpacing.s4)
            }
            .refreshable { await vm.load() }
        }
        .overlay(alignment: .top) {
            if let error = vm.error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)
                Text(DateFormatter.display.string(from: Date()))
                    .font(FTTypography.bodySM)
                    .foregroundStyle(FTColor.textSecondary)
            }
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Circle()
                    .fill(FTColor.primarySoft)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person")
                            .foregroundStyle(FTColor.primary)
                    )
            }
        }
    }

    private var greeting: String {
        if case .signedIn(let user) = authService.state {
            let name = user.email.components(separatedBy: "@").first?.capitalized ?? "there"
            return "Hi, \(name)"
        }
        return "Hello"
    }

    // MARK: - Balance Hero Card

    private var balanceHeroCard: some View {
        VStack(alignment: .leading, spacing: FTSpacing.s3) {
            Text("Total balance")
                .font(FTTypography.label)
                .foregroundStyle(.white.opacity(0.8))

            Text(CurrencyFormatter.format(vm.totalBalance, currency: "KZT"))
                .font(FTTypography.displayXL)
                .foregroundStyle(.white)

            Divider().overlay(.white.opacity(0.2))

            HStack {
                Label(CurrencyFormatter.format(vm.monthlyIncome, currency: "KZT"), systemImage: "arrow.up")
                    .font(FTTypography.numericMD)
                    .foregroundStyle(.white.opacity(0.85))
                    .labelStyle(.titleAndIcon)

                Spacer()

                Divider()
                    .frame(height: 16)
                    .overlay(.white.opacity(0.4))

                Spacer()

                Label(CurrencyFormatter.format(vm.monthlyExpenses, currency: "KZT"), systemImage: "arrow.down")
                    .font(FTTypography.numericMD)
                    .foregroundStyle(.white.opacity(0.85))
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(FTSpacing.s6)
        .background(FTColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.xl))
        .shadow(color: FTColor.primary.opacity(0.3), radius: 16, y: 6)
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: FTSpacing.s3) {
            quickStat(label: "Accounts", value: "\(vm.accounts.count)")
            quickStat(label: "This month", value: CurrencyFormatter.format(vm.monthlyExpenses, currency: "KZT"))
            quickStat(label: "Net", value: CurrencyFormatter.format(vm.monthlyIncome - vm.monthlyExpenses, currency: "KZT"))
        }
    }

    private func quickStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: FTSpacing.s1) {
            Text(label)
                .font(FTTypography.bodySM)
                .foregroundStyle(FTColor.textSecondary)
            Text(value)
                .font(FTTypography.numericMD)
                .foregroundStyle(FTColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(FTSpacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: FTSpacing.s3) {
            HStack {
                Text("Recent transactions")
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)
                Spacer()
                NavigationLink(destination: AllTransactionsView(apiClient: apiClient)) {
                    Text("See all")
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.primary)
                }
            }

            if vm.recentTransactions.isEmpty {
                FTEmptyState(
                    icon: "tray",
                    title: "No transactions yet",
                    message: "Tap + to add your first one."
                )
                .background(FTColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
            } else {
                FTCard {
                    ForEach(Array(vm.recentTransactions.enumerated()), id: \.element.id) { idx, tx in
                        NavigationLink(destination: TransactionDetailView(transaction: tx, apiClient: apiClient)) {
                            TransactionRow(transaction: tx, showDivider: idx < vm.recentTransactions.count - 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

}

// MARK: - All Transactions View

struct AllTransactionsView: View {
    let apiClient: APIClient

    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var error: APIError?

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()
            if isLoading && transactions.isEmpty {
                ProgressView()
            } else if transactions.isEmpty {
                FTEmptyState(icon: "tray", title: "No transactions", message: "Add your first transaction.")
            } else {
                List {
                    ForEach(transactions) { tx in
                        NavigationLink(destination: TransactionDetailView(transaction: tx, apiClient: apiClient)) {
                            TransactionRow(transaction: tx, showDivider: false)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(FTColor.surface)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("All Transactions")
        .overlay(alignment: .top) {
            if let e = error {
                FTErrorBanner(message: e.userMessage, retryAction: { Task { await load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            let result = try await apiClient.sendPaginated(
                Endpoint.Transactions.list(filters: .init(perPage: 50)), as: Transaction.self)
            transactions = result.items
        } catch let e as APIError { error = e } catch { self.error = .network }
    }
}


#Preview {
    NavigationStack {
        HomeView()
            .environment(AppEnvironment())
    }
}
