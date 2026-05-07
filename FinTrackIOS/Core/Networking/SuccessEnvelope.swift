import Foundation

struct SuccessEnvelope<T: Decodable>: Decodable {
    let error: Bool
    let data: T
}
