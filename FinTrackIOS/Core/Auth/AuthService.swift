import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class AuthService {
    private(set) var state: SessionState = .unknown

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Lifecycle

    func bootstrap() async {
        guard (try? KeychainStore.read(.accessToken)) != nil else {
            state = .signedOut
            return
        }
        do {
            let user = try await apiClient.send(Endpoint.Auth.me, as: User.self)
            state = .signedIn(user)
        } catch APIError.unauthorized {
            do {
                try await refresh()
                let user = try await apiClient.send(Endpoint.Auth.me, as: User.self)
                state = .signedIn(user)
            } catch {
                clearSession()
            }
        } catch {
            Log.auth.error("Bootstrap error: \(error)")
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        let response = try await apiClient.send(
            Endpoint.Auth.login(email: email, password: password),
            as: AuthResponse.self
        )
        try storeTokens(response.tokens)
        state = .signedIn(response.user)
    }

    func signUp(email: String, password: String, baseCurrency: String) async throws {
        let response = try await apiClient.send(
            Endpoint.Auth.register(email: email, password: password, baseCurrency: baseCurrency),
            as: AuthResponse.self
        )
        try storeTokens(response.tokens)
        state = .signedIn(response.user)
    }

    func refresh() async throws {
        guard let refreshToken = try? KeychainStore.read(.refreshToken) else {
            throw APIError.unauthorized
        }
        let response = try await apiClient.send(
            Endpoint.Auth.refresh(token: refreshToken),
            as: RefreshResponse.self
        )
        try KeychainStore.write(response.accessToken, for: .accessToken)
        try KeychainStore.write(response.refreshToken, for: .refreshToken)
        Log.auth.info("Tokens refreshed successfully")
    }

    func signOut() async {
        try? await apiClient.sendVoid(Endpoint.Auth.logout)
        clearSession()
    }

    func forceSignOut() {
        clearSession()
    }

    // MARK: - Private

    private func storeTokens(_ tokens: TokenPair) throws {
        try KeychainStore.write(tokens.accessToken, for: .accessToken)
        try KeychainStore.write(tokens.refreshToken, for: .refreshToken)
    }

    private func clearSession() {
        try? KeychainStore.deleteAll()
        state = .signedOut
    }
}
