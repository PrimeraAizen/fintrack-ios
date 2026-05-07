import Foundation

struct ExchangeRate: Codable, Hashable, Sendable {
    let from: String
    let to: String
    let rate: Decimal
    let updatedAt: Date
}

// MARK: - Preview

extension ExchangeRate {
    static let preview = ExchangeRate(
        from: "USD",
        to: "KZT",
        rate: 450,
        updatedAt: Date()
    )
}
