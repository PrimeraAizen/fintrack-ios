import Foundation

/// Property wrapper that decodes Decimal from either a JSON string ("100.00") or a JSON number (100.00).
/// shopspring/decimal in Go serializes as quoted strings; this wrapper accepts both formats.
@propertyWrapper
struct StringOrDecimal: Codable, Sendable, Hashable, Equatable {
    var wrappedValue: Decimal

    init(wrappedValue: Decimal) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            guard let d = Decimal(string: str) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot parse Decimal from string: \(str)"
                )
            }
            wrappedValue = d
        } else {
            wrappedValue = try container.decode(Decimal.self)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
