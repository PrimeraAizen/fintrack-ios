import Foundation

enum CategoryType: String, Codable, CaseIterable, Sendable {
    case income, expense

    var displayName: String {
        switch self {
        case .income:  "Income"
        case .expense: "Expense"
        }
    }
}

struct Category: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let name: String
    let icon: String?
    let color: String?
    let type: CategoryType
    let createdAt: Date
}

// MARK: - Preview

extension Category {
    static let previewExpense = Category(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        userID: User.preview.id,
        name: "Groceries",
        icon: "cart",
        color: "#E8A87C",
        type: .expense,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    static let previewIncome = Category(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
        userID: User.preview.id,
        name: "Salary",
        icon: "briefcase",
        color: "#5B8A72",
        type: .income,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
