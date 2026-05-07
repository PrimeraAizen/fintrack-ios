import Foundation

actor AuthInterceptor {
    private var refreshTask: Task<Void, Error>?

    /// Guarantees only one refresh is in-flight at a time.
    /// Concurrent callers that arrive while a refresh is running will await the same task.
    func refresh(using refresher: @escaping @Sendable () async throws -> Void) async throws {
        if let existing = refreshTask {
            return try await existing.value
        }

        let task = Task<Void, Error> { try await refresher() }
        refreshTask = task

        defer { refreshTask = nil }

        try await task.value
    }
}
