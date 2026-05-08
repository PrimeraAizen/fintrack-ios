import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var accounts: [Account] = []
    private(set) var recentTransactions: [Transaction] = []
    private(set) var isLoading = false
    var error: APIError?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let accts = apiClient.send(Endpoint.Accounts.list, as: [Account].self)
            async let txns  = apiClient.sendPaginated(
                Endpoint.Transactions.list(filters: .init(perPage: 5)),
                as: Transaction.self
            )
            let (a, t) = try await (accts, txns)
            accounts = a
            recentTransactions = t.items
        } catch let e as APIError {
            error = e
            Log.ui.error("Home load error: \(e)")
        } catch {
            self.error = .network
        }
    }

    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var monthlyIncome: Decimal {
        recentTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.convertedAmount }
    }

    var monthlyExpenses: Decimal {
        recentTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.convertedAmount }
    }
}
