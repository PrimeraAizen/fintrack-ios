import Foundation

struct Transfer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let fromAccountID: UUID
    let toAccountID: UUID
    @StringOrDecimal var amount: Decimal
    let fromCurrency: String
    let toCurrency: String
    @StringOrDecimal var exchangeRate: Decimal
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fromAccountID = "fromAccountId"
        case toAccountID = "toAccountId"
        case amount
        case fromCurrency
        case toCurrency
        case exchangeRate
        case createdAt
    }
}

// MARK: - Preview

extension Transfer {
    static let preview = Transfer(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000050")!,
        fromAccountID: Account.preview.id,
        toAccountID: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        amount: 100,
        fromCurrency: "USD",
        toCurrency: "KZT",
        exchangeRate: 450,
        createdAt: Date(timeIntervalSince1970: 1_716_000_000)
    )
}
