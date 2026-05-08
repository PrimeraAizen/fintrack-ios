import Foundation
import OSLog

// MARK: - Protocol

protocol APIClientProtocol {
    func send<R: Decodable & Sendable>(_ endpoint: Endpoint, as type: R.Type) async throws -> R
    func sendPaginated<R: Decodable & Sendable>(_ endpoint: Endpoint, as type: R.Type) async throws -> Paginated<R>
    func sendVoid(_ endpoint: Endpoint) async throws
    func sendData(_ endpoint: Endpoint) async throws -> Data
    func uploadCSV(at fileURL: URL) async throws -> CSVImportResult
}

struct CSVImportResult: Decodable, Sendable {
    let imported: Int
    let failed: Int
    let errors: [String]?
}

// MARK: - APIClient

final class APIClient: APIClientProtocol {

    // Injected by AppCoordinator after AuthService is ready (Task 11).
    var getAccessToken: (() -> String?)?
    var performRefresh: (@Sendable () async throws -> Void)?
    var onSessionExpired: (() async -> Void)?

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let interceptor = AuthInterceptor()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = .finTrack
        self.encoder = .finTrack
    }

    static func fromPlist() -> APIClient {
        guard
            let raw = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
            let url = URL(string: raw)
        else {
            fatalError("API_BASE_URL is missing or invalid in Info.plist")
        }
        return APIClient(baseURL: url)
    }
}

// MARK: - APIClientProtocol

extension APIClient {

    func send<R: Decodable & Sendable>(_ endpoint: Endpoint, as type: R.Type) async throws -> R {
        let data = try await execute(endpoint)
        return try decode(SuccessEnvelope<R>.self, from: data).data
    }

    func sendPaginated<R: Decodable & Sendable>(_ endpoint: Endpoint, as type: R.Type) async throws -> Paginated<R> {
        let data = try await execute(endpoint)
        return try decode(SuccessEnvelope<Paginated<R>>.self, from: data).data
    }

    func sendVoid(_ endpoint: Endpoint) async throws {
        _ = try await execute(endpoint)
    }

    func sendData(_ endpoint: Endpoint) async throws -> Data {
        return try await execute(endpoint)
    }

    func uploadCSV(at fileURL: URL) async throws -> CSVImportResult {
        var request = try buildRequest(Endpoint.Transactions.import)
        let boundary = "FT-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildMultipart(fileURL: fileURL, boundary: boundary)

        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse else { throw APIError.network }
        try validate(data, response: http)
        return try decode(SuccessEnvelope<CSVImportResult>.self, from: data).data
    }
}

// MARK: - Private

private extension APIClient {

    func execute(_ endpoint: Endpoint, isRetry: Bool = false) async throws -> Data {
        let request = try buildRequest(endpoint)
        let (data, response) = try await perform(request)

        guard let http = response as? HTTPURLResponse else { return data }

        if http.statusCode == 401, endpoint.requiresAuth, !isRetry {
            do {
                guard let refresh = performRefresh else { throw APIError.unauthorized }
                try await interceptor.refresh(using: refresh)
            } catch {
                await onSessionExpired?()
                throw APIError.unauthorized
            }
            return try await execute(endpoint, isRetry: true)
        }

        try validate(data, response: http)
        return data
    }

    func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path ?? ""
        components?.path = basePath + "/api/v1" + endpoint.path
        components?.queryItems = endpoint.query

        guard let url = components?.url else {
            Log.api.error("Failed to build URL for path: \(endpoint.path)")
            throw APIError.network
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = getAccessToken?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            Log.api.error("Network error: \(urlError.localizedDescription)")
            throw APIError.network
        }
    }

    func validate(_ data: Data, response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            let envelope = try? decoder.decode(ErrorEnvelope.self, from: data)
            throw APIError.validation(envelope?.details ?? [:])
        case 429:
            throw APIError.rateLimited
        case 500...599:
            let envelope = try? decoder.decode(ErrorEnvelope.self, from: data)
            Log.api.error("Server error \(response.statusCode): \(envelope?.message ?? "")")
            throw APIError.server(message: envelope?.message ?? "")
        default:
            let envelope = try? decoder.decode(ErrorEnvelope.self, from: data)
            throw APIError.unknown(
                code: envelope?.code ?? String(response.statusCode),
                message: envelope?.message ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            )
        }
    }

    func buildMultipart(fileURL: URL, boundary: String) throws -> Data {
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        var body = Data()
        body.append(contentsOf: "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\nContent-Type: text/csv\r\n\r\n".utf8)
        body.append(fileData)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)
        return body
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            Log.api.error("Decoding error for \(T.self): \(error)")
            throw APIError.decoding
        }
    }
}

// MARK: - Shared JSON coders

extension JSONDecoder {
    static let finTrack: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            for fmt in JSONDecoder.iso8601Formatters {
                if let date = fmt.date(from: str) { return date }
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Cannot parse date: \(str)"
            ))
        }
        return d
    }()

    private static let iso8601Formatters: [ISO8601DateFormatter] = {
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFrac, plain]
    }()
}

extension JSONEncoder {
    static let finTrack: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(fmt.string(from: date))
        }
        return e
    }()
}

// MARK: - AnyEncodable

private struct AnyEncodable: Encodable {
    private let base: any Encodable
    init(_ base: any Encodable) { self.base = base }
    func encode(to encoder: Encoder) throws { try base.encode(to: encoder) }
}
