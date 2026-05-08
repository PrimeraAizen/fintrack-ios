import SwiftUI

struct CategoriesManagementView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _CategoriesBody(apiClient: env.apiClient)
    }
}

private struct _CategoriesBody: View {
    @State private var vm: CategoriesViewModel

    init(apiClient: APIClient) {
        _vm = State(wrappedValue: CategoriesViewModel(apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            if vm.isLoading && vm.categories.isEmpty {
                ProgressView()
            } else if vm.categories.isEmpty {
                FTEmptyState(
                    icon: "tag",
                    title: "No categories yet",
                    message: "Create categories to organize your transactions and budgets.",
                    actionTitle: "Create your first category",
                    action: { vm.showCreateSheet = true }
                )
            } else {
                List {
                    if !vm.expenseCategories.isEmpty {
                        Section("Expense") {
                            ForEach(vm.expenseCategories) { cat in
                                categoryRow(cat)
                            }
                        }
                    }
                    if !vm.incomeCategories.isEmpty {
                        Section("Income") {
                            ForEach(vm.incomeCategories) { cat in
                                categoryRow(cat)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.showCreateSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $vm.showCreateSheet) {
            CategoryFormView(onSave: { name, icon, color, type in
                Task { await vm.create(name: name, icon: icon, color: color, type: type) }
            })
        }
        .sheet(item: $vm.editingCategory) { cat in
            CategoryFormView(editing: cat, onSave: { name, icon, color, _ in
                Task { await vm.update(cat, name: name, icon: icon, color: color) }
            })
        }
        .overlay(alignment: .top) {
            if let error = vm.error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func categoryRow(_ cat: Category) -> some View {
        HStack(spacing: FTSpacing.s3) {
            CategoryIcon(icon: cat.icon, color: nil)
            Text(cat.name)
                .font(FTTypography.bodyMD)
                .foregroundStyle(FTColor.textPrimary)
            Spacer()
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await vm.delete(cat) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { vm.editingCategory = cat } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(FTColor.primary)
        }
    }
}

// MARK: - Category Form

struct CategoryFormView: View {
    let editing: Category?
    let onSave: (String, String?, String?, CategoryType) -> Void

    init(editing: Category? = nil, onSave: @escaping (String, String?, String?, CategoryType) -> Void) {
        self.editing = editing
        self.onSave = onSave
    }

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedType: CategoryType = .expense

    private let icons = ["tag", "cart", "fork.knife", "car", "house", "figure.walk",
                         "heart", "book", "gamecontroller", "airplane", "tshirt", "pills",
                         "gift", "wrench", "briefcase", "graduationcap"]

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                VStack(spacing: FTSpacing.s5) {
                    FTTextField(label: "Name", placeholder: "e.g. Groceries", text: $name)
                        .padding(.horizontal, FTSpacing.s4)

                    VStack(alignment: .leading, spacing: FTSpacing.s2) {
                        Text("Type")
                            .font(FTTypography.label)
                            .foregroundStyle(FTColor.textSecondary)
                            .padding(.horizontal, FTSpacing.s4)

                        Picker("Type", selection: $selectedType) {
                            Text("Expense").tag(CategoryType.expense)
                            Text("Income").tag(CategoryType.income)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, FTSpacing.s4)
                    }

                    VStack(alignment: .leading, spacing: FTSpacing.s2) {
                        Text("Icon")
                            .font(FTTypography.label)
                            .foregroundStyle(FTColor.textSecondary)
                            .padding(.horizontal, FTSpacing.s4)

                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: FTSpacing.s3) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 22))
                                        .foregroundStyle(selectedIcon == icon ? FTColor.primary : FTColor.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? FTColor.primarySoft : FTColor.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: FTRadius.md))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, FTSpacing.s4)
                    }

                    Spacer()
                }
                .padding(.top, FTSpacing.s4)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text(editing == nil ? "New Category" : "Edit Category")
                        .font(FTTypography.headingMD)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard !name.isEmpty else { return }
                        onSave(name, selectedIcon, nil, selectedType)
                        dismiss()
                    }
                    .font(FTTypography.headingMD)
                    .foregroundStyle(name.isEmpty ? FTColor.textTertiary : FTColor.primary)
                }
            }
        }
        .onAppear {
            if let cat = editing {
                name = cat.name
                selectedIcon = cat.icon ?? "tag"
                selectedType = cat.type
            }
        }
    }
}

// MARK: - Category Icon Helper

struct CategoryIcon: View {
    let icon: String?
    let color: String?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill((color.flatMap { Color(hex: $0) } ?? FTColor.primary).opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: icon ?? "tag")
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(color.flatMap { Color(hex: $0) } ?? FTColor.primary)
        }
    }
}

// Hex color convenience (accepts "#RRGGBB")
private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

#Preview {
    CategoriesManagementView()
        .environment(AppEnvironment())
}
