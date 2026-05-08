import Foundation

@MainActor @Observable final class SavingGoalsViewModel {
    private(set) var goals: [SavingGoal] = []
    private(set) var isLoading = false
    var error: APIError?

    // Create form
    var showCreateSheet = false
    var editingGoal: SavingGoal?

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            goals = try await apiClient.send(Endpoint.SavingGoals.list, as: [SavingGoal].self)
        } catch let e as APIError { error = e } catch { self.error = .network }
    }

    func create(name: String, targetAmount: Decimal, currency: String, deadline: Date?) async {
        let deadlineStr = deadline.map { DateFormatter.monthParam.string(from: $0) }
        do {
            let created = try await apiClient.send(
                Endpoint.SavingGoals.create(name: name, targetAmount: targetAmount, currency: currency, deadline: deadlineStr),
                as: SavingGoal.self)
            goals.append(created)
        } catch let e as APIError { error = e } catch { self.error = .network }
    }

    func updateAmount(goal: SavingGoal, newAmount: Decimal) async {
        do {
            let updated = try await apiClient.send(
                Endpoint.SavingGoals.update(id: goal.id, currentAmount: newAmount),
                as: SavingGoal.self)
            if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[idx] = updated
            }
        } catch let e as APIError { error = e } catch { self.error = .network }
    }

    func delete(goal: SavingGoal) async {
        do {
            try await apiClient.sendVoid(Endpoint.SavingGoals.delete(id: goal.id))
            goals.removeAll { $0.id == goal.id }
        } catch let e as APIError { error = e } catch { self.error = .network }
    }

    func progressFraction(for goal: SavingGoal) -> Decimal {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1)
    }

    var totalSaved: Decimal { goals.reduce(0) { $0 + $1.currentAmount } }
    var totalTarget: Decimal { goals.reduce(0) { $0 + $1.targetAmount } }
    var completedCount: Int { goals.filter { $0.currentAmount >= $0.targetAmount }.count }
}
