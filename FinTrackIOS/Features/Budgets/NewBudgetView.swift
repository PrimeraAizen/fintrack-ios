import SwiftUI

struct NewBudgetView: View {
    let period: BudgetPeriod
    let apiClient: APIClient
    let onSave: (UUID, Decimal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []
    @State private var selectedCategory: Category?
    @State private var limitText = ""
    @State private var categoryError: String?
    @State private var limitError: String?

    private var limit: Decimal { Decimal(string: limitText) ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                VStack(spacing: FTSpacing.s5) {
                    VStack(alignment: .leading, spacing: FTSpacing.s2) {
                        Text("Category")
                            .font(FTTypography.label)
                            .foregroundStyle(FTColor.textSecondary)

                        if categories.isEmpty {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Menu {
                                ForEach(categories.filter { $0.type == .expense }) { cat in
                                    Button { selectedCategory = cat } label: {
                                        Label(cat.name, systemImage: cat.icon ?? "tag")
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory?.name ?? "Select expense category")
                                        .font(FTTypography.bodyMD)
                                        .foregroundStyle(selectedCategory == nil ? FTColor.textTertiary : FTColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 13))
                                        .foregroundStyle(FTColor.textTertiary)
                                }
                                .padding(FTSpacing.s4)
                                .background(FTColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FTRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FTRadius.md)
                                        .strokeBorder(categoryError != nil ? FTColor.danger : FTColor.border, lineWidth: 1)
                                )
                            }
                        }
                        if let e = categoryError {
                            Text(e).font(FTTypography.bodySM).foregroundStyle(FTColor.danger)
                        }
                    }

                    FTTextField(label: "Spending limit (\(period.displayName))",
                                placeholder: "e.g. 50000",
                                text: $limitText,
                                keyboardType: .decimalPad,
                                errorMessage: limitError)

                    Text("Period: \(period.displayName)")
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textSecondary)

                    Spacer()
                }
                .padding(FTSpacing.s4)

                VStack {
                    Spacer()
                    FTButton("Create budget") {
                        categoryError = nil; limitError = nil
                        guard let cat = selectedCategory else { categoryError = "Select a category"; return }
                        guard limit > 0 else { limitError = "Enter a spending limit"; return }
                        onSave(cat.id, limit)
                        dismiss()
                    }
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
                    Text("New Budget").font(FTTypography.headingMD)
                }
            }
            .task {
                if let cats = try? await apiClient.send(Endpoint.Categories.list(type: "expense"), as: [Category].self) {
                    categories = cats
                }
            }
        }
    }
}
