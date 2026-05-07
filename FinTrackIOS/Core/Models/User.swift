import Foundation

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let email: String
    let baseCurrency: String
    let createdAt: Date
}

struct AuthResponse: Decodable, Sendable {
    let user: User
    let tokens: TokenPair
}

struct TokenPair: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
}

struct RefreshResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Preview

extension User {
    static let preview = User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "demo@fintrack.kz",
        baseCurrency: "KZT",
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
