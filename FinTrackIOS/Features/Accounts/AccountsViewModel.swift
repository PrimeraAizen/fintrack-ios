import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class AccountsViewModel {
    private(set) var accounts: [Account] = []
    private(set) var isLoading = false
    var error: APIError?
    var showNewAccountSheet = false
    var showTransferSheet = false

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            accounts = try await apiClient.send(Endpoint.Accounts.list, as: [Account].self)
        } catch let e as APIError {
            error = e
            Log.ui.error("Failed to load accounts: \(e)")
        } catch {
            self.error = .network
        }
    }

    func create(name: String, type: AccountType, currency: String, balance: Decimal) async {
        do {
            let new = try await apiClient.send(
                Endpoint.Accounts.create(name: name, type: type.rawValue, currency: currency, balance: balance),
                as: Account.self
            )
            accounts.append(new)
            showNewAccountSheet = false
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    func delete(_ account: Account) async {
        do {
            try await apiClient.sendVoid(Endpoint.Accounts.delete(id: account.id))
            accounts.removeAll { $0.id == account.id }
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }
}
