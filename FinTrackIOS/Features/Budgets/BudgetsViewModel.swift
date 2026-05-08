import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class BudgetsViewModel {
    private(set) var budgets: [Budget] = []
    private(set) var isLoading = false
    var error: APIError?
    var showNewBudgetSheet = false
    var period: BudgetPeriod = .monthly

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            budgets = try await apiClient.send(
                Endpoint.Budgets.list(period: period.rawValue),
                as: [Budget].self
            )
        } catch let e as APIError {
            error = e
            Log.ui.error("Failed to load budgets: \(e)")
        } catch {
            self.error = .network
        }
    }

    func create(categoryID: UUID, spendingLimit: Decimal) async {
        do {
            let new = try await apiClient.send(
                Endpoint.Budgets.create(categoryID: categoryID, spendingLimit: spendingLimit, period: period.rawValue),
                as: Budget.self
            )
            budgets.append(new)
            showNewBudgetSheet = false
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    func delete(_ budget: Budget) async {
        do {
            try await apiClient.sendVoid(Endpoint.Budgets.delete(id: budget.id))
            budgets.removeAll { $0.id == budget.id }
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    var totalSpent: Decimal    { budgets.reduce(0) { $0 + $1.spent } }
    var totalLimit: Decimal    { budgets.reduce(0) { $0 + $1.spendingLimit } }
    var exceededCount: Int     { budgets.filter(\.exceeded).count }
    var onTrackCount: Int      { budgets.filter { !$0.exceeded }.count }
}
