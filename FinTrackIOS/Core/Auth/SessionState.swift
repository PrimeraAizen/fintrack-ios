import Foundation

enum SessionState: Equatable {
    case unknown
    case signedOut
    case signedIn(User)
}
