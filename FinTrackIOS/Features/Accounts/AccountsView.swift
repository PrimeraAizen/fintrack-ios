import SwiftUI

struct AccountsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _AccountsBody(apiClient: env.apiClient)
    }
}

private struct _AccountsBody: View {
    @State private var vm: AccountsViewModel
    let apiClient: APIClient

    init(apiClient: APIClient) {
        _vm = State(wrappedValue: AccountsViewModel(apiClient: apiClient))
        self.apiClient = apiClient
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: FTSpacing.s3) {
                    if vm.isLoading && vm.accounts.isEmpty {
                        ProgressView().padding(.top, FTSpacing.s12)
                    } else if vm.accounts.isEmpty {
                        FTEmptyState(
                            icon: "creditcard",
                            title: "No accounts yet",
                            message: "Add your first account to start tracking your balance.",
                            actionTitle: "Add Account",
                            action: { vm.showNewAccountSheet = true }
                        )
                        .padding(.top, FTSpacing.s8)
                    } else {
                        // Total summary card
                        HStack {
                            VStack(alignment: .leading, spacing: FTSpacing.s1) {
                                Text("All accounts total")
                                    .font(FTTypography.label)
                                    .foregroundStyle(FTColor.textSecondary)
                                Text(CurrencyFormatter.format(vm.totalBalance, currency: "KZT"))
                                    .font(FTTypography.displayLG)
                                    .foregroundStyle(FTColor.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(FTSpacing.s4)
                        .background(FTColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(FTColor.primary)
                                .frame(width: 4)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .padding(.vertical, FTSpacing.s2)
                        }
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        .padding(.horizontal, FTSpacing.s4)

                        ForEach(vm.accounts) { account in
                            NavigationLink(destination: AccountDetailView(account: account, apiClient: apiClient)) {
                                AccountCard(account: account)
                                    .padding(.horizontal, FTSpacing.s4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, FTSpacing.s4)
            }
            .refreshable { await vm.load() }

            // Transfer floating button
            if vm.accounts.count >= 2 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            vm.showTransferSheet = true
                        } label: {
                            Label("Transfer", systemImage: "arrow.left.arrow.right")
                                .font(FTTypography.label)
                                .foregroundStyle(.white)
                                .padding(.horizontal, FTSpacing.s4)
                                .padding(.vertical, FTSpacing.s2)
                                .background(FTColor.primary)
                                .clipShape(Capsule())
                        }
                        .padding(.trailing, FTSpacing.s4)
                        .padding(.bottom, FTSpacing.s4)
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.showNewAccountSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $vm.showNewAccountSheet) {
            NewAccountView { name, type, currency, balance in
                Task { await vm.create(name: name, type: type, currency: currency, balance: balance) }
            }
        }
        .sheet(isPresented: $vm.showTransferSheet) {
            TransferView(accounts: vm.accounts, onComplete: { Task { await vm.load() } })
        }
        .overlay(alignment: .top) {
            if let error = vm.error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await vm.load() }
    }
}

// MARK: - Account Card

struct AccountCard: View {
    let account: Account

    private var typeColor: Color {
        switch account.type {
        case .cash:    FTColor.catMint
        case .card:    FTColor.catSlate
        case .savings: FTColor.catTeal
        case .other:   FTColor.catSand
        }
    }

    var body: some View {
        FTCard {
            VStack(spacing: FTSpacing.s3) {
                HStack(spacing: FTSpacing.s3) {
                    ZStack {
                        Circle()
                            .fill(typeColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: account.type.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(typeColor)
                    }

                    Text(account.name)
                        .font(FTTypography.headingMD)
                        .foregroundStyle(FTColor.textPrimary)

                    Spacer()

                    Text(account.type.displayName)
                        .font(FTTypography.label)
                        .foregroundStyle(FTColor.primary)
                        .padding(.horizontal, FTSpacing.s2)
                        .padding(.vertical, 3)
                        .background(FTColor.primarySoft)
                        .clipShape(Capsule())
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(CurrencyFormatter.format(account.balance, currency: account.currency))
                        .font(FTTypography.numericLG)
                        .foregroundStyle(FTColor.textPrimary)
                    Spacer()
                    Text(account.currency)
                        .font(FTTypography.bodySM)
                        .foregroundStyle(FTColor.textSecondary)
                }
            }
            .padding(FTSpacing.s4)
        }
    }
}

#Preview {
    NavigationStack {
        AccountsView()
            .environment(AppEnvironment())
    }
}
