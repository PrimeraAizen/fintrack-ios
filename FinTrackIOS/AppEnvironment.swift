import Foundation
import Observation

@MainActor @Observable
final class AppEnvironment {
    let apiClient: APIClient
    let authService: AuthService
    let preferences: PreferencesStore
    let rateCache = ExchangeRateCache()

    init() {
        let client = APIClient.fromPlist()
        let auth   = AuthService(apiClient: client)
        let prefs  = PreferencesStore()

        apiClient   = client
        authService = auth
        preferences = prefs

        // Wire token injection — reads directly from Keychain (thread-safe, no data race)
        client.getAccessToken = { try? KeychainStore.read(.accessToken) }

        client.performRefresh = { [weak auth] in
            guard let auth else { throw APIError.unauthorized }
            try await auth.refresh()
        }

        client.onSessionExpired = { [weak auth] in
            await MainActor.run { auth?.forceSignOut() }
        }
    }
}
