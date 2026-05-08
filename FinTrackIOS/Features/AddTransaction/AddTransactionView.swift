import SwiftUI

struct AddTransactionView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _AddTransactionBody(apiClient: env.apiClient)
    }
}

private struct _AddTransactionBody: View {
    @State private var vm: AddTransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCategoryPicker = false
    @State private var showAccountPicker = false
    @State private var showBudgetAlert = false

    init(apiClient: APIClient) {
        _vm = State(wrappedValue: AddTransactionViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: FTSpacing.s5) {
                        // Type toggle
                        Picker("Type", selection: $vm.type) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, FTSpacing.s4)

                        // Amount
                        amountSection

                        // Form rows
                        FTCard {
                            VStack(spacing: 0) {
                                pickerRow(
                                    icon: "tag",
                                    label: vm.selectedCategory?.name ?? "Category",
                                    placeholder: vm.selectedCategory == nil,
                                    error: vm.categoryError
                                ) { showCategoryPicker = true }

                                Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)

                                pickerRow(
                                    icon: vm.selectedAccount.map { $0.type.iconName } ?? "creditcard",
                                    label: vm.selectedAccount?.name ?? "Account",
                                    placeholder: vm.selectedAccount == nil,
                                    error: vm.accountError
                                ) { showAccountPicker = true }

                                Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)

                                DatePicker(
                                    "Date",
                                    selection: $vm.date,
                                    displayedComponents: .date
                                )
                                .padding(.horizontal, FTSpacing.s4)
                                .frame(minHeight: 56)

                                Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)

                                TextField("Add a note (optional)", text: $vm.note)
                                    .font(FTTypography.bodyMD)
                                    .foregroundStyle(FTColor.textPrimary)
                                    .padding(.horizontal, FTSpacing.s4)
                                    .frame(minHeight: 56)
                            }
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
                    FTButton("Save transaction", isLoading: vm.isLoading) {
                        Task {
                            if await vm.save() {
                                if vm.budgetExceeded == true {
                                    showBudgetAlert = true
                                } else {
                                    dismiss()
                                }
                            }
                        }
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
                    Text("New transaction").font(FTTypography.headingMD)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(categories: vm.filteredCategories, selected: $vm.selectedCategory)
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerSheet(accounts: vm.accounts, selected: $vm.selectedAccount)
            }
            .alert("Budget exceeded", isPresented: $showBudgetAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("This transaction puts you over budget for this category.")
            }
            .task { await vm.loadPickerData() }
        }
    }

    private var amountSection: some View {
        VStack(spacing: FTSpacing.s1) {
            HStack(alignment: .center, spacing: FTSpacing.s1) {
                Text(CurrencyFormatter.symbol(for: vm.currency))
                    .font(FTTypography.displayLG)
                    .foregroundStyle(FTColor.textTertiary)

                TextField("0", text: $vm.amountText)
                    .font(FTTypography.displayLG)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(FTColor.textPrimary)
            }
            .frame(maxWidth: .infinity)

            if let amountError = vm.amountError {
                Text(amountError)
                    .font(FTTypography.bodySM)
                    .foregroundStyle(FTColor.danger)
            }
        }
        .padding(.vertical, FTSpacing.s4)
    }

    private func pickerRow(icon: String, label: String, placeholder: Bool, error: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: FTSpacing.s3) {
                Image(systemName: icon)
                    .foregroundStyle(FTColor.textSecondary)
                    .frame(width: 22)

                Text(label)
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(placeholder ? FTColor.textTertiary : FTColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FTColor.textTertiary)
            }
            .padding(.horizontal, FTSpacing.s4)
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if let e = error {
                Text(e)
                    .font(FTTypography.bodySM)
                    .foregroundStyle(FTColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FTSpacing.s4)
                    .offset(y: 12)
            }
        }
    }
}

// MARK: - Category Picker Sheet

private struct CategoryPickerSheet: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(categories) { cat in
                Button {
                    selected = cat
                    dismiss()
                } label: {
                    HStack(spacing: FTSpacing.s3) {
                        CategoryIcon(icon: cat.icon, color: nil)
                        Text(cat.name)
                            .font(FTTypography.bodyMD)
                            .foregroundStyle(FTColor.textPrimary)
                        Spacer()
                        if selected?.id == cat.id {
                            Image(systemName: "checkmark").foregroundStyle(FTColor.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(FTColor.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FTColor.bg)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
            }
        }
    }
}

// MARK: - Account Picker Sheet

private struct AccountPickerSheet: View {
    let accounts: [Account]
    @Binding var selected: Account?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(accounts) { acc in
                Button {
                    selected = acc
                    dismiss()
                } label: {
                    HStack(spacing: FTSpacing.s3) {
                        Image(systemName: acc.type.iconName)
                            .foregroundStyle(FTColor.primary)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text(acc.name).font(FTTypography.bodyMD).foregroundStyle(FTColor.textPrimary)
                            Text(CurrencyFormatter.format(acc.balance, currency: acc.currency))
                                .font(FTTypography.bodySM).foregroundStyle(FTColor.textSecondary)
                        }
                        Spacer()
                        if selected?.id == acc.id {
                            Image(systemName: "checkmark").foregroundStyle(FTColor.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(FTColor.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FTColor.bg)
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
            }
        }
    }
}

#Preview {
    AddTransactionView()
        .environment(AppEnvironment())
}
