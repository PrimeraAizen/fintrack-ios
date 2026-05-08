import Foundation

/// Thread-safe in-memory cache for exchange rates.
/// Serves a cached rate if it was fetched within `maxAge`; otherwise calls the fetcher.
actor ExchangeRateCache {
    private struct Entry {
        let rate: ExchangeRate
        let fetchedAt: Date
    }

    private var store: [String: Entry] = [:]
    let maxAge: TimeInterval

    init(maxAge: TimeInterval = 30 * 60) {
        self.maxAge = maxAge
    }

    func rate(
        from: String,
        to: String,
        fetcher: () async throws -> ExchangeRate
    ) async throws -> ExchangeRate {
        let key = "\(from)-\(to)"

        if let entry = store[key], Date().timeIntervalSince(entry.fetchedAt) < maxAge {
            return entry.rate
        }

        let fresh = try await fetcher()
        store[key] = Entry(rate: fresh, fetchedAt: Date())
        return fresh
    }

    func invalidate() {
        store.removeAll()
    }
}
