import Foundation

enum APIError: Error, Equatable {
    case unauthorized
    case forbidden
    case notFound
    case validation([String: String])
    case rateLimited
    case server(message: String)
    case network
    case decoding
    case unknown(code: String, message: String)
}

extension APIError: LocalizedError {
    var userMessage: String {
        switch self {
        case .unauthorized:              "Your session has expired. Please sign in again."
        case .forbidden:                 "You don't have permission to do that."
        case .notFound:                  "The requested resource was not found."
        case .validation(let fields):    fields.values.first ?? "Please check your input and try again."
        case .rateLimited:               "Too many requests. Please wait a moment."
        case .server(let msg):           msg.isEmpty ? "A server error occurred. Try again later." : msg
        case .network:                   "No internet connection. Check your network and retry."
        case .decoding:                  "Received unexpected data from the server."
        case .unknown(_, let msg):       msg.isEmpty ? "An unexpected error occurred." : msg
        }
    }

    var errorDescription: String? { userMessage }
}
