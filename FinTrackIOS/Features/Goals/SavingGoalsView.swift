import SwiftUI

struct SavingGoalsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _SavingGoalsBody(apiClient: env.apiClient)
    }
}

private struct _SavingGoalsBody: View {
    @State private var vm: SavingGoalsViewModel
    @State private var showCreate = false
    @State private var addingToGoal: SavingGoal?

    init(apiClient: APIClientProtocol) {
        _vm = State(wrappedValue: SavingGoalsViewModel(apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            if vm.isLoading && vm.goals.isEmpty {
                ProgressView()
            } else if vm.goals.isEmpty {
                FTEmptyState(
                    icon: "flag",
                    title: "No saving goals",
                    message: "Set a target and track your progress.",
                    actionTitle: "New goal",
                    action: { showCreate = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: FTSpacing.s4) {
                        summaryCard
                            .padding(.horizontal, FTSpacing.s4)

                        ForEach(vm.goals) { goal in
                            GoalCard(goal: goal, fraction: vm.progressFraction(for: goal)) {
                                addingToGoal = goal
                            }
                            .padding(.horizontal, FTSpacing.s4)
                        }
                    }
                    .padding(.vertical, FTSpacing.s4)
                }
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("Saving Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(FTColor.primary)
                }
            }
        }
        .overlay(alignment: .top) {
            if let e = vm.error {
                FTErrorBanner(message: e.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .sheet(isPresented: $showCreate) {
            NewGoalView { name, amount, currency, deadline in
                await vm.create(name: name, targetAmount: amount, currency: currency, deadline: deadline)
            }
        }
        .sheet(item: $addingToGoal) { goal in
            AddFundsView(goal: goal) { newAmount in
                await vm.updateAmount(goal: goal, newAmount: newAmount)
            }
        }
        .task { await vm.load() }
    }

    private var summaryCard: some View {
        FTCard {
            HStack {
                summaryPair(label: "Total saved", value: CurrencyFormatter.format(vm.totalSaved, currency: "KZT"))
                Spacer()
                Divider().frame(height: 28)
                Spacer()
                summaryPair(label: "Total target", value: CurrencyFormatter.format(vm.totalTarget, currency: "KZT"))
                Spacer()
                Divider().frame(height: 28)
                Spacer()
                summaryPair(label: "Completed", value: "\(vm.completedCount)/\(vm.goals.count)")
            }
            .padding(FTSpacing.s4)
        }
    }

    private func summaryPair(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(FTTypography.bodySM).foregroundStyle(FTColor.textSecondary)
            Text(value).font(FTTypography.numericMD).foregroundStyle(FTColor.textPrimary)
        }
    }
}

// MARK: - Goal Card

private struct GoalCard: View {
    let goal: SavingGoal
    let fraction: Decimal
    let onAddFunds: () -> Void

    private var isComplete: Bool { goal.currentAmount >= goal.targetAmount }

    private var deadlineCaption: String? {
        guard let d = goal.deadline else { return nil }
        if isComplete { return "Goal reached!" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
        return days > 0 ? "\(days) days left" : "Deadline passed"
    }

    var body: some View {
        FTCard {
            VStack(alignment: .leading, spacing: FTSpacing.s3) {
                HStack {
                    Text(goal.name)
                        .font(FTTypography.headingMD)
                        .foregroundStyle(FTColor.textPrimary)
                    Spacer()
                    if isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(FTColor.income)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(CurrencyFormatter.format(goal.currentAmount, currency: goal.currency ?? "KZT"))
                            .font(FTTypography.numericMD)
                            .foregroundStyle(FTColor.textPrimary)
                        Text("of \(CurrencyFormatter.format(goal.targetAmount, currency: goal.currency ?? "KZT"))")
                            .font(FTTypography.bodySM)
                            .foregroundStyle(FTColor.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(NSDecimalNumber(decimal: fraction).doubleValue * 100))%")
                        .font(FTTypography.numericMD)
                        .foregroundStyle(isComplete ? FTColor.income : FTColor.primary)
                }

                FTProgressBar(value: goal.currentAmount, total: goal.targetAmount)
                    .frame(height: 8)

                HStack {
                    if let caption = deadlineCaption {
                        Text(caption)
                            .font(FTTypography.bodySM)
                            .foregroundStyle(isComplete ? FTColor.income : FTColor.textSecondary)
                    }
                    Spacer()
                    if !isComplete {
                        Button(action: onAddFunds) {
                            Text("Add funds")
                                .font(FTTypography.bodySM)
                                .foregroundStyle(FTColor.primary)
                        }
                    }
                }
            }
            .padding(FTSpacing.s4)
        }
    }
}

// MARK: - New Goal Sheet

private struct NewGoalView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, Decimal, String, Date?) async -> Void

    @State private var name = ""
    @State private var amountText = ""
    @State private var currency = "KZT"
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var isSaving = false

    private let currencies = ["KZT", "USD", "EUR"]
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount > 0 }
    private var parsedAmount: Decimal { Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()
                Form {
                    Section("Goal") {
                        FTTextField(label: "Goal name", placeholder: "e.g. New Laptop", text: $name)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        FTTextField(label: "Target amount", placeholder: "0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        .font(FTTypography.bodyMD)
                    }
                    .listRowBackground(FTColor.surface)

                    Section("Deadline") {
                        Toggle("Set a deadline", isOn: $hasDeadline)
                            .font(FTTypography.bodyMD)
                            .tint(FTColor.primary)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .font(FTTypography.bodyMD)
                        }
                    }
                    .listRowBackground(FTColor.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("New Goal").font(FTTypography.headingMD)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            await onSave(name, parsedAmount, currency, hasDeadline ? deadline : nil)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!isValid || isSaving)
                    .foregroundStyle(isValid ? FTColor.primary : FTColor.textTertiary)
                }
            }
        }
    }
}

// MARK: - Add Funds Sheet

private struct AddFundsView: View {
    @Environment(\.dismiss) private var dismiss

    let goal: SavingGoal
    var onSave: (Decimal) async -> Void

    @State private var amountText = ""
    @State private var isSaving = false

    private var parsedAmount: Decimal { Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var newTotal: Decimal { goal.currentAmount + parsedAmount }
    private var isValid: Bool { parsedAmount > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()
                VStack(spacing: FTSpacing.s6) {
                    Spacer()

                    VStack(spacing: FTSpacing.s2) {
                        Text(goal.name)
                            .font(FTTypography.headingLG)
                            .foregroundStyle(FTColor.textPrimary)
                        Text("\(CurrencyFormatter.format(goal.currentAmount, currency: goal.currency ?? "KZT")) of \(CurrencyFormatter.format(goal.targetAmount, currency: goal.currency ?? "KZT"))")
                            .font(FTTypography.bodyMD)
                            .foregroundStyle(FTColor.textSecondary)
                    }

                    FTProgressBar(value: parsedAmount > 0 ? newTotal : goal.currentAmount, total: goal.targetAmount)
                        .frame(height: 8)
                        .padding(.horizontal, FTSpacing.s4)
                        .animation(.easeInOut, value: amountText)

                    FTTextField(label: "Amount", placeholder: "0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, FTSpacing.s4)

                    if parsedAmount > 0 {
                        Text("New total: \(CurrencyFormatter.format(newTotal, currency: goal.currency ?? "KZT"))")
                            .font(FTTypography.bodyMD)
                            .foregroundStyle(FTColor.textSecondary)
                    }

                    Spacer()

                    FTButton("Add funds", isLoading: isSaving) {
                        isSaving = true
                        Task {
                            await onSave(newTotal)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, FTSpacing.s4)
                    .padding(.bottom, FTSpacing.s8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Add Funds").font(FTTypography.headingMD)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavingGoalsView()
            .environment(AppEnvironment())
    }
}
