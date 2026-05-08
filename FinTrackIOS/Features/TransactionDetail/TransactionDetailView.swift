import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let apiClient: APIClient

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var error: APIError?

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: FTSpacing.s4) {
                    // Hero amount
                    VStack(spacing: FTSpacing.s1) {
                        Text(CurrencyFormatter.format(transaction.amount, currency: transaction.currency))
                            .font(FTTypography.displayLG)
                            .foregroundStyle(transaction.type == .income ? FTColor.income : FTColor.textPrimary)

                        if transaction.currency != "KZT" {
                            Text("≈ \(CurrencyFormatter.format(transaction.convertedAmount, currency: "KZT"))")
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FTSpacing.s4)

                    // Metadata
                    FTCard {
                        VStack(spacing: 0) {
                            metaRow(icon: "tag", label: "Category", value: "—")
                            Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)
                            metaRow(icon: transaction.type == .income ? "arrow.down" : "arrow.up",
                                    label: "Type", value: transaction.type.displayName)
                            Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)
                            metaRow(icon: "calendar", label: "Date",
                                    value: DateFormatter.display.string(from: transaction.transactionDate))
                            if let note = transaction.note, !note.isEmpty {
                                Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)
                                metaRow(icon: "note.text", label: "Note", value: note)
                            }
                        }
                    }
                    .padding(.horizontal, FTSpacing.s4)

                    if let error {
                        FTErrorBanner(message: error.userMessage)
                            .padding(.horizontal, FTSpacing.s4)
                    }

                    // Delete
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text(isDeleting ? "Deleting…" : "Delete transaction")
                            .font(FTTypography.bodyLG)
                            .foregroundStyle(FTColor.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FTSpacing.s3)
                    }
                    .disabled(isDeleting)
                }
                .padding(.vertical, FTSpacing.s4)
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await delete() }
            }
        }
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: FTSpacing.s3) {
            Image(systemName: icon)
                .foregroundStyle(FTColor.textSecondary)
                .frame(width: 22)
            Text(label)
                .font(FTTypography.bodyMD)
                .foregroundStyle(FTColor.textSecondary)
            Spacer()
            Text(value)
                .font(FTTypography.bodyMD)
                .foregroundStyle(FTColor.textPrimary)
        }
        .padding(.horizontal, FTSpacing.s4)
        .frame(minHeight: 52)
    }

    private func delete() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await apiClient.sendVoid(Endpoint.Transactions.delete(id: transaction.id))
            dismiss()
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }
}

// MARK: - Transaction Row (shared)

struct TransactionRow: View {
    let transaction: Transaction
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: FTSpacing.s3) {
                // Category icon placeholder
                ZStack {
                    Circle()
                        .fill(FTColor.primary.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "tag")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(FTColor.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.note ?? transaction.type.displayName)
                        .font(FTTypography.bodyLG)
                        .foregroundStyle(FTColor.textPrimary)
                        .lineLimit(1)
                    Text(RelativeTimeFormatter.string(from: transaction.transactionDate))
                        .font(FTTypography.bodySM)
                        .foregroundStyle(FTColor.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text((transaction.type == .income ? "+" : "") +
                         CurrencyFormatter.format(transaction.amount, currency: transaction.currency))
                        .font(FTTypography.numericMD)
                        .foregroundStyle(transaction.type == .income ? FTColor.income : FTColor.textPrimary)
                    Text(RelativeTimeFormatter.string(from: transaction.transactionDate))
                        .font(FTTypography.bodySM)
                        .foregroundStyle(FTColor.textTertiary)
                }
            }
            .frame(minHeight: 64)
            .padding(.horizontal, FTSpacing.s4)

            if showDivider {
                Divider()
                    .overlay(FTColor.border)
                    .padding(.leading, FTSpacing.s4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(transaction: .preview, apiClient: APIClient.fromPlist())
    }
}
