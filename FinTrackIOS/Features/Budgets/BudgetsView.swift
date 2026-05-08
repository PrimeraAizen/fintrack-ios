import SwiftUI

struct BudgetsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _BudgetsBody(apiClient: env.apiClient)
    }
}

private struct _BudgetsBody: View {
    @State private var vm: BudgetsViewModel
    let apiClient: APIClient

    init(apiClient: APIClient) {
        _vm = State(wrappedValue: BudgetsViewModel(apiClient: apiClient))
        self.apiClient = apiClient
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: FTSpacing.s4) {
                    // Period selector
                    Picker("Period", selection: $vm.period) {
                        Text("Weekly").tag(BudgetPeriod.weekly)
                        Text("Monthly").tag(BudgetPeriod.monthly)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, FTSpacing.s4)
                    .onChange(of: vm.period) { _, _ in Task { await vm.load() } }

                    if vm.isLoading && vm.budgets.isEmpty {
                        ProgressView().padding(.top, FTSpacing.s12)
                    } else if vm.budgets.isEmpty {
                        FTEmptyState(
                            icon: "chart.bar",
                            title: "No budgets yet",
                            message: "Set spending limits by category to start tracking your spending.",
                            actionTitle: "Set up a budget",
                            action: { vm.showNewBudgetSheet = true }
                        )
                        .padding(.top, FTSpacing.s4)
                    } else {
                        // Summary card
                        summaryCard
                            .padding(.horizontal, FTSpacing.s4)

                        // Budget cards
                        ForEach(vm.budgets) { budget in
                            NavigationLink(destination: BudgetDetailView(budget: budget, apiClient: apiClient)) {
                                BudgetCard(budget: budget)
                                    .padding(.horizontal, FTSpacing.s4)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await vm.delete(budget) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, FTSpacing.s4)
            }
            .refreshable { await vm.load() }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.showNewBudgetSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $vm.showNewBudgetSheet) {
            NewBudgetView(period: vm.period, apiClient: apiClient) { catID, limit in
                Task { await vm.create(categoryID: catID, spendingLimit: limit) }
            }
        }
        .overlay(alignment: .top) {
            if let error = vm.error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await vm.load() }
    }

    private var summaryCard: some View {
        FTCard {
            VStack(alignment: .leading, spacing: FTSpacing.s3) {
                Text("Spent \(CurrencyFormatter.format(vm.totalSpent, currency: "KZT")) of \(CurrencyFormatter.format(vm.totalLimit, currency: "KZT"))")
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.textSecondary)

                FTProgressBar(value: vm.totalSpent, total: vm.totalLimit > 0 ? vm.totalLimit : 1)
                    .frame(height: 12)

                HStack {
                    Label("\(vm.onTrackCount) on track", systemImage: "checkmark.circle")
                        .font(FTTypography.bodySM)
                        .foregroundStyle(FTColor.primary)
                    if vm.exceededCount > 0 {
                        Spacer()
                        Label("\(vm.exceededCount) exceeded", systemImage: "exclamationmark.circle")
                            .font(FTTypography.bodySM)
                            .foregroundStyle(FTColor.danger)
                    }
                }
            }
            .padding(FTSpacing.s4)
        }
    }
}

// MARK: - Budget Card

struct BudgetCard: View {
    let budget: Budget

    private var fraction: Double {
        guard budget.spendingLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: budget.spent / budget.spendingLimit).doubleValue
    }

    private var caption: String {
        if budget.exceeded {
            let over = budget.spent - budget.spendingLimit
            return "Over by \(CurrencyFormatter.format(over, currency: "KZT"))"
        }
        let days = daysRemaining
        return days > 0 ? "\(days) days left" : "Period ending today"
    }

    private var captionColor: Color {
        budget.exceeded ? FTColor.danger : FTColor.textTertiary
    }

    private var daysRemaining: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let end: Date
        switch budget.period {
        case .weekly:  end = cal.date(byAdding: .day,   value: 7, to: budget.periodStart) ?? today
        case .monthly: end = cal.date(byAdding: .month, value: 1, to: budget.periodStart) ?? today
        }
        return max(0, cal.dateComponents([.day], from: today, to: end).day ?? 0)
    }

    var body: some View {
        FTCard {
            VStack(spacing: FTSpacing.s3) {
                HStack(spacing: FTSpacing.s3) {
                    Image(systemName: "tag")
                        .font(.system(size: 16))
                        .foregroundStyle(FTColor.primary)
                        .frame(width: 32, height: 32)
                        .background(FTColor.primarySoft)
                        .clipShape(Circle())

                    Text("Budget")
                        .font(FTTypography.headingMD)
                        .foregroundStyle(FTColor.textPrimary)

                    Spacer()

                    Text("\(CurrencyFormatter.format(budget.spent, currency: "KZT")) / \(CurrencyFormatter.format(budget.spendingLimit, currency: "KZT"))")
                        .font(FTTypography.numericMD)
                        .foregroundStyle(FTColor.textPrimary)
                }

                FTProgressBar(value: budget.spent, total: budget.spendingLimit)
                    .frame(height: 8)

                HStack {
                    Text(caption)
                        .font(FTTypography.bodySM)
                        .foregroundStyle(captionColor)
                    Spacer()
                    Text(budget.period.displayName)
                        .font(FTTypography.bodySM)
                        .foregroundStyle(FTColor.textTertiary)
                }
            }
            .padding(FTSpacing.s4)
        }
    }
}

#Preview {
    NavigationStack {
        BudgetsView()
            .environment(AppEnvironment())
    }
}
