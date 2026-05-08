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
    let name: String
    let icon: String?
    let type: CategoryType
    let createdAt: Date
}

// MARK: - Preview

extension Category {
    static let previewExpense = Category(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        name: "Groceries",
        icon: "cart",
        type: .expense,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    static let previewIncome = Category(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
        name: "Salary",
        icon: "briefcase",
        type: .income,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
