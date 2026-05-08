import Foundation
import Observation

/// Tracks navigation state for the unauthenticated flow.
/// (Future: deep-link routing, push notification destinations)
@MainActor
@Observable
final class AppCoordinator {
    /// When `true`, show SignIn instead of Onboarding for a signed-out user.
    var showSignIn = false
}
