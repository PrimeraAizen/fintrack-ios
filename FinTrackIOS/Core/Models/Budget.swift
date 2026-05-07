import Foundation

enum BudgetPeriod: String, Codable, CaseIterable, Sendable {
    case weekly, monthly

    var displayName: String {
        switch self {
        case .weekly:  "Weekly"
        case .monthly: "Monthly"
        }
    }
}

struct Budget: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let categoryID: UUID
    let spendingLimit: Decimal
    let spent: Decimal
    let remaining: Decimal
    let period: BudgetPeriod
    let periodStart: Date
    let exceeded: Bool
    let createdAt: Date
}

// MARK: - Preview

extension Budget {
    static let preview = Budget(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!,
        userID: User.preview.id,
        categoryID: Category.previewExpense.id,
        spendingLimit: 50_000,
        spent: 32_000,
        remaining: 18_000,
        period: .monthly,
        periodStart: Date(timeIntervalSince1970: 1_714_521_600),
        exceeded: false,
        createdAt: Date(timeIntervalSince1970: 1_714_521_600)
    )
}
