import Foundation

enum CurrencyFormatter {

    /// Formats a `Decimal` amount as a locale-aware currency string.
    /// KZT uses thin-space (U+202F) as the thousands separator per Kazakh convention.
    static func format(_ amount: Decimal, currency: String, locale: Locale = .current) -> String {
        let formatter = numberFormatter(for: currency, locale: locale)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? fallback(amount, currency: currency)
    }

    /// Returns just the currency symbol for a given code.
    static func symbol(for code: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        return formatter.currencySymbol
    }

    // MARK: - Private

    private static func numberFormatter(for currency: String, locale: Locale) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.locale = locale
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2

        if currency == "KZT" {
            f.groupingSeparator = "\u{202F}"
            f.groupingSize = 3
            f.usesGroupingSeparator = true
        }

        return f
    }

    private static func fallback(_ amount: Decimal, currency: String) -> String {
        "\(amount) \(currency)"
    }
}
