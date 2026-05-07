import Foundation

/// In-memory mock for SwiftUI Previews and unit tests.
///
/// Usage in a preview:
/// ```swift
/// let mock = MockAPIClient()
/// mock.stub(path: "/accounts", response: [Account.preview])
/// ```
final class MockAPIClient: APIClientProtocol {

    // Recorded calls for test assertions
    private(set) var capturedEndpoints: [Endpoint] = []

    // Global error override — all calls throw this if set
    var stubbedError: APIError?

    private var stubs:           [String: Any] = [:]
    private var paginatedStubs:  [String: Any] = [:]

    // MARK: - Configuration

    func stub<R>(path: String, response: R) {
        stubs[path] = response
    }

    func stubPaginated<R>(path: String, items: [R], pagination: PaginationInfo = .init(page: 1, perPage: 20, total: 1, totalPages: 1)) {
        paginatedStubs[path] = Paginated(items: items, pagination: pagination)
    }

    func reset() {
        capturedEndpoints.removeAll()
        stubs.removeAll()
        paginatedStubs.removeAll()
        stubbedError = nil
    }

    // MARK: - APIClientProtocol

    func send<R: Decodable>(_ endpoint: Endpoint, as type: R.Type) async throws -> R {
        capturedEndpoints.append(endpoint)
        if let error = stubbedError { throw error }
        guard let response = stubs[endpoint.path] as? R else {
            throw APIError.unknown(code: "mock_missing", message: "No stub for \(endpoint.path) → \(R.self)")
        }
        return response
    }

    func sendPaginated<R: Decodable>(_ endpoint: Endpoint, as type: R.Type) async throws -> Paginated<R> {
        capturedEndpoints.append(endpoint)
        if let error = stubbedError { throw error }
        guard let response = paginatedStubs[endpoint.path] as? Paginated<R> else {
            throw APIError.unknown(code: "mock_missing", message: "No paginated stub for \(endpoint.path) → \(R.self)")
        }
        return response
    }

    func sendVoid(_ endpoint: Endpoint) async throws {
        capturedEndpoints.append(endpoint)
        if let error = stubbedError { throw error }
    }
}
