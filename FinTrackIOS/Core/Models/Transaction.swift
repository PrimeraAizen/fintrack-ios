import Foundation

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income, expense

    var displayName: String {
        switch self {
        case .income:  "Income"
        case .expense: "Expense"
        }
    }
}

struct Transaction: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let accountID: UUID
    let categoryID: UUID
    let type: TransactionType
    let amount: Decimal
    let currency: String
    let convertedAmount: Decimal
    let note: String?
    let transactionDate: Date
    let createdAt: Date
}

/// Returned inside `data` when creating a transaction.
struct CreateTransactionResponse: Decodable, Sendable {
    let transaction: Transaction
    let budgetExceeded: Bool?
}

// MARK: - Preview

extension Transaction {
    static let preview = Transaction(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
        accountID: Account.preview.id,
        categoryID: Category.previewExpense.id,
        type: .expense,
        amount: 4_200,
        currency: "KZT",
        convertedAmount: 4_200,
        note: "Magnum",
        transactionDate: Date(timeIntervalSince1970: 1_716_000_000),
        createdAt: Date(timeIntervalSince1970: 1_716_000_000)
    )
}
