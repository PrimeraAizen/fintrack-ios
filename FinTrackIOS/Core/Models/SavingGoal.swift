import Foundation

struct SavingGoal: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let currency: String
    let deadline: Date?
    let createdAt: Date
}

// MARK: - Preview

extension SavingGoal {
    static let preview = SavingGoal(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000060")!,
        userID: User.preview.id,
        name: "New Laptop",
        targetAmount: 400_000,
        currentAmount: 120_000,
        currency: "KZT",
        deadline: Date(timeIntervalSince1970: 1_735_689_600),
        createdAt: Date(timeIntervalSince1970: 1_714_521_600)
    )
}
