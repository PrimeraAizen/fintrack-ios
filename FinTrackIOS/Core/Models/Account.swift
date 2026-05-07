import Foundation

enum AccountType: String, Codable, CaseIterable, Sendable {
    case cash, card, savings, other

    var displayName: String {
        switch self {
        case .cash:    "Cash"
        case .card:    "Card"
        case .savings: "Savings"
        case .other:   "Other"
        }
    }

    var iconName: String {
        switch self {
        case .cash:    "banknote"
        case .card:    "creditcard"
        case .savings: "building.columns"
        case .other:   "folder"
        }
    }

    /// Types shown in the New Account picker. `other` is decoded but not offered at creation.
    static var creationOptions: [AccountType] { [.cash, .card, .savings] }
}

struct Account: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userID: UUID
    let name: String
    let type: AccountType
    let currency: String
    let balance: Decimal
    let createdAt: Date
}

// MARK: - Preview

extension Account {
    static let preview = Account(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        userID: User.preview.id,
        name: "Main Card",
        type: .card,
        currency: "KZT",
        balance: 450_000,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
