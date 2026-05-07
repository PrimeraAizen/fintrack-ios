import Foundation

struct Paginated<T: Decodable>: Decodable {
    let items: [T]
    let pagination: PaginationInfo
}

struct PaginationInfo: Decodable, Sendable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
}
