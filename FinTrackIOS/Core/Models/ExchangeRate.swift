import Foundation

struct ExchangeRate: Codable, Hashable, Sendable {
    let from: String
    let to: String
    @StringOrDecimal var rate: Decimal
    let cachedAt: Date
}

// MARK: - Preview

extension ExchangeRate {
    static let preview = ExchangeRate(from: "USD", to: "KZT", rate: 450, cachedAt: Date())
}
