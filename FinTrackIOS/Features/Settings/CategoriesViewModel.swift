import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class CategoriesViewModel {
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    var error: APIError?
    var showCreateSheet = false
    var editingCategory: Category?

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            categories = try await apiClient.send(Endpoint.Categories.list(), as: [Category].self)
        } catch let e as APIError {
            error = e
            Log.ui.error("Failed to load categories: \(e)")
        } catch {
            self.error = .network
        }
    }

    func create(name: String, icon: String?, color: String?, type: CategoryType) async {
        do {
            let new = try await apiClient.send(
                Endpoint.Categories.create(name: name, icon: icon, color: color, type: type.rawValue),
                as: Category.self
            )
            categories.append(new)
            showCreateSheet = false
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    func update(_ category: Category, name: String, icon: String?, color: String?) async {
        do {
            let updated = try await apiClient.send(
                Endpoint.Categories.update(id: category.id, name: name, icon: icon, color: color),
                as: Category.self
            )
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                categories[idx] = updated
            }
            editingCategory = nil
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    func delete(_ category: Category) async {
        do {
            try await apiClient.sendVoid(Endpoint.Categories.delete(id: category.id))
            categories.removeAll { $0.id == category.id }
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }

    var incomeCategories: [Category] { categories.filter { $0.type == .income } }
    var expenseCategories: [Category] { categories.filter { $0.type == .expense } }
}
