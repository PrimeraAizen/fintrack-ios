import Foundation

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income, expense

    var displayName: String {
        switch self {
        case .income:  "Income"
        case .expense: "Expense"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case Self.income.rawValue, "credit", "inflow":
            self = .income
        case Self.expense.rawValue, "debit", "outflow":
            self = .expense
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize TransactionType from invalid String value: \(rawValue)"
            )
        }
    }
}

struct Transaction: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let accountID: UUID
    let categoryID: UUID
    let type: TransactionType
    @StringOrDecimal var amount: Decimal
    let currency: String
    @StringOrDecimal var convertedAmount: Decimal
    let note: String?
    let transactionDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "accountId"
        case categoryID = "categoryId"
        case type
        case amount
        case currency
        case convertedAmount
        case note
        case transactionDate
        case createdAt
    }
}

/// Returned inside `data` when creating a transaction.
struct CreateTransactionResponse: Decodable, Sendable {
    let budgetExceeded: Bool?

    private enum CodingKeys: String, CodingKey {
        case budgetExceeded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        budgetExceeded = try container.decodeIfPresent(Bool.self, forKey: .budgetExceeded)
    }
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
