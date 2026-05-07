import Foundation

struct Transfer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let fromAccountID: UUID
    let toAccountID: UUID
    let amount: Decimal
    let convertedAmount: Decimal
    let fromCurrency: String
    let toCurrency: String
    let exchangeRate: Decimal
    let note: String?
    let transferDate: Date
    let createdAt: Date
}

// MARK: - Preview

extension Transfer {
    static let preview = Transfer(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000050")!,
        fromAccountID: Account.preview.id,
        toAccountID: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        amount: 100,
        convertedAmount: 45_000,
        fromCurrency: "USD",
        toCurrency: "KZT",
        exchangeRate: 450,
        note: nil,
        transferDate: Date(timeIntervalSince1970: 1_716_000_000),
        createdAt: Date(timeIntervalSince1970: 1_716_000_000)
    )
}
