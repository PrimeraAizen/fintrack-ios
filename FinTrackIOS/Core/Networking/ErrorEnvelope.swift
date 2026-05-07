import Foundation

struct ErrorEnvelope: Decodable {
    let error: Bool
    let code: String
    let message: String
    let details: [String: String]?
}
