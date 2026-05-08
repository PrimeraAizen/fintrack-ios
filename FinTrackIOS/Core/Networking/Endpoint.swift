import Foundation

struct Endpoint: @unchecked Sendable {
    let method: HTTPMethod
    let path: String
    let query: [URLQueryItem]?
    let body: (any Encodable)?
    let requiresAuth: Bool

    init(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Auth
extension Endpoint {
    enum Auth {}
}

extension Endpoint.Auth {
    static func login(email: String, password: String) -> Endpoint {
        struct Body: Encodable { let email: String; let password: String }
        return Endpoint(method: .post, path: "/auth/login", body: Body(email: email, password: password), requiresAuth: false)
    }

    static func register(email: String, password: String, baseCurrency: String) -> Endpoint {
        struct Body: Encodable { let email: String; let password: String; let baseCurrency: String }
        return Endpoint(method: .post, path: "/auth/register", body: Body(email: email, password: password, baseCurrency: baseCurrency), requiresAuth: false)
    }

    static func refresh(token: String) -> Endpoint {
        struct Body: Encodable { let refreshToken: String }
        return Endpoint(method: .post, path: "/auth/refresh", body: Body(refreshToken: token), requiresAuth: false)
    }

    static var logout: Endpoint {
        Endpoint(method: .post, path: "/auth/logout")
    }

    static var me: Endpoint {
        Endpoint(method: .get, path: "/me")
    }
}

// MARK: - Accounts
extension Endpoint {
    enum Accounts {}
}

extension Endpoint.Accounts {
    static var list: Endpoint {
        Endpoint(method: .get, path: "/accounts")
    }

    static func get(id: UUID) -> Endpoint {
        Endpoint(method: .get, path: "/accounts/\(id)")
    }

    static func create(name: String, type: String, currency: String, balance: Decimal) -> Endpoint {
        struct Body: Encodable { let name: String; let type: String; let currency: String; let balance: Decimal }
        return Endpoint(method: .post, path: "/accounts", body: Body(name: name, type: type, currency: currency, balance: balance))
    }

    static func update(id: UUID, name: String?, currency: String?) -> Endpoint {
        struct Body: Encodable { let name: String?; let currency: String? }
        return Endpoint(method: .patch, path: "/accounts/\(id)", body: Body(name: name, currency: currency))
    }

    static func delete(id: UUID) -> Endpoint {
        Endpoint(method: .delete, path: "/accounts/\(id)")
    }
}

// MARK: - Categories
extension Endpoint {
    enum Categories {}
}

extension Endpoint.Categories {
    static func list(type: String? = nil) -> Endpoint {
        var query: [URLQueryItem]? = nil
        if let type { query = [URLQueryItem(name: "type", value: type)] }
        return Endpoint(method: .get, path: "/categories", query: query)
    }

    static func create(name: String, icon: String?, color: String?, type: String) -> Endpoint {
        struct Body: Encodable { let name: String; let icon: String?; let color: String?; let type: String }
        return Endpoint(method: .post, path: "/categories", body: Body(name: name, icon: icon, color: color, type: type))
    }

    static func update(id: UUID, name: String?, icon: String?, color: String?) -> Endpoint {
        struct Body: Encodable { let name: String?; let icon: String?; let color: String? }
        return Endpoint(method: .patch, path: "/categories/\(id)", body: Body(name: name, icon: icon, color: color))
    }

    static func delete(id: UUID) -> Endpoint {
        Endpoint(method: .delete, path: "/categories/\(id)")
    }
}

// MARK: - Transactions
extension Endpoint {
    enum Transactions {}
}

extension Endpoint.Transactions {
    struct Filters {
        var from: String? = nil
        var to: String? = nil
        var accountID: UUID? = nil
        var categoryID: UUID? = nil
        var type: String? = nil
        var page: Int? = nil
        var perPage: Int? = nil

        var queryItems: [URLQueryItem] {
            var items: [URLQueryItem] = []
            if let from       { items.append(.init(name: "from",      value: from)) }
            if let to         { items.append(.init(name: "to",        value: to)) }
            if let accountID  { items.append(.init(name: "account",   value: accountID.uuidString)) }
            if let categoryID { items.append(.init(name: "category",  value: categoryID.uuidString)) }
            if let type       { items.append(.init(name: "type",      value: type)) }
            if let page       { items.append(.init(name: "page",      value: "\(page)")) }
            if let perPage    { items.append(.init(name: "per_page",  value: "\(perPage)")) }
            return items
        }
    }

    static func list(filters: Filters = .init()) -> Endpoint {
        let q = filters.queryItems
        return Endpoint(method: .get, path: "/transactions", query: q.isEmpty ? nil : q)
    }

    static func get(id: UUID) -> Endpoint {
        Endpoint(method: .get, path: "/transactions/\(id)")
    }

    static func create(accountID: UUID, categoryID: UUID, amount: Decimal, currency: String, note: String?, date: Date, type: String) -> Endpoint {
        struct Body: Encodable {
            let accountID: UUID; let categoryID: UUID; let amount: Decimal
            let currency: String; let note: String?; let transactionDate: Date; let type: String
        }
        return Endpoint(method: .post, path: "/transactions",
                        body: Body(accountID: accountID, categoryID: categoryID, amount: amount,
                                   currency: currency, note: note, transactionDate: date, type: type))
    }

    static func update(id: UUID, note: String?, categoryID: UUID?) -> Endpoint {
        struct Body: Encodable { let note: String?; let categoryID: UUID? }
        return Endpoint(method: .patch, path: "/transactions/\(id)", body: Body(note: note, categoryID: categoryID))
    }

    static func delete(id: UUID) -> Endpoint {
        Endpoint(method: .delete, path: "/transactions/\(id)")
    }

    static var `import`: Endpoint {
        Endpoint(method: .post, path: "/transactions/import")
    }

    static func export(from: String? = nil, to: String? = nil, accountID: UUID? = nil, categoryID: UUID? = nil) -> Endpoint {
        var q: [URLQueryItem] = []
        if let from       { q.append(.init(name: "from",     value: from)) }
        if let to         { q.append(.init(name: "to",       value: to)) }
        if let accountID  { q.append(.init(name: "account",  value: accountID.uuidString)) }
        if let categoryID { q.append(.init(name: "category", value: categoryID.uuidString)) }
        return Endpoint(method: .get, path: "/transactions/export", query: q.isEmpty ? nil : q)
    }
}

// MARK: - Transfers
extension Endpoint {
    enum Transfers {}
}

extension Endpoint.Transfers {
    static func create(fromAccountID: UUID, toAccountID: UUID, amount: Decimal, note: String?, date: String) -> Endpoint {
        struct Body: Encodable {
            let fromAccountID: UUID; let toAccountID: UUID; let amount: Decimal; let note: String?; let transferDate: String
        }
        return Endpoint(method: .post, path: "/transfers",
                        body: Body(fromAccountID: fromAccountID, toAccountID: toAccountID, amount: amount, note: note, transferDate: date))
    }

    static var list: Endpoint {
        Endpoint(method: .get, path: "/transfers")
    }
}

// MARK: - Budgets
extension Endpoint {
    enum Budgets {}
}

extension Endpoint.Budgets {
    static func list(period: String? = nil) -> Endpoint {
        let q = period.map { [URLQueryItem(name: "period", value: $0)] }
        return Endpoint(method: .get, path: "/budgets", query: q)
    }

    static func create(categoryID: UUID, spendingLimit: Decimal, period: String) -> Endpoint {
        struct Body: Encodable { let categoryID: UUID; let spendingLimit: Decimal; let period: String }
        return Endpoint(method: .post, path: "/budgets", body: Body(categoryID: categoryID, spendingLimit: spendingLimit, period: period))
    }

    static func update(id: UUID, spendingLimit: Decimal) -> Endpoint {
        struct Body: Encodable { let spendingLimit: Decimal }
        return Endpoint(method: .patch, path: "/budgets/\(id)", body: Body(spendingLimit: spendingLimit))
    }

    static func delete(id: UUID) -> Endpoint {
        Endpoint(method: .delete, path: "/budgets/\(id)")
    }
}

// MARK: - Reports
extension Endpoint {
    enum Reports {}
}

extension Endpoint.Reports {
    static func weekly(weekOf: String) -> Endpoint {
        Endpoint(method: .get, path: "/reports/weekly", query: [.init(name: "weekOf", value: weekOf)])
    }

    static func monthly(month: String) -> Endpoint {
        Endpoint(method: .get, path: "/reports/monthly", query: [.init(name: "month", value: month)])
    }
}

// MARK: - Exchange Rates
extension Endpoint {
    enum ExchangeRates {}
}

extension Endpoint.ExchangeRates {
    static func rate(from: String, to: String) -> Endpoint {
        Endpoint(method: .get, path: "/exchange-rates", query: [.init(name: "from", value: from), .init(name: "to", value: to)])
    }
}

// MARK: - Saving Goals
extension Endpoint {
    enum SavingGoals {}
}

extension Endpoint.SavingGoals {
    static var list: Endpoint { Endpoint(method: .get, path: "/saving-goals") }

    static func create(name: String, targetAmount: Decimal, currency: String, deadline: String?) -> Endpoint {
        struct Body: Encodable { let name: String; let targetAmount: Decimal; let currency: String; let deadline: String? }
        return Endpoint(method: .post, path: "/saving-goals", body: Body(name: name, targetAmount: targetAmount, currency: currency, deadline: deadline))
    }

    static func update(id: UUID, currentAmount: Decimal) -> Endpoint {
        struct Body: Encodable { let currentAmount: Decimal }
        return Endpoint(method: .patch, path: "/saving-goals/\(id)", body: Body(currentAmount: currentAmount))
    }

    static func delete(id: UUID) -> Endpoint {
        Endpoint(method: .delete, path: "/saving-goals/\(id)")
    }
}
