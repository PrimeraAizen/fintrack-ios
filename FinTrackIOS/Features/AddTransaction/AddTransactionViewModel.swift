import Foundation
import Observation

@MainActor
@Observable
final class AddTransactionViewModel {
    var type: TransactionType = .expense
    var amountText = ""
    var currency = "KZT"
    var selectedCategory: Category?
    var selectedAccount: Account?
    var date = Date()
    var note = ""
    var isLoading = false
    var error: APIError?
    var amountError: String?
    var categoryError: String?
    var accountError: String?
    var budgetExceeded: Bool?

    private(set) var categories: [Category] = []
    private(set) var accounts: [Account] = []

    private let apiClient: APIClient

    var amount: Decimal { Decimal(string: amountText) ?? 0 }
    var isValid: Bool { amount > 0 && selectedCategory != nil && selectedAccount != nil }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadPickerData() async {
        async let cats = apiClient.send(Endpoint.Categories.list(), as: [Category].self)
        async let accts = apiClient.send(Endpoint.Accounts.list, as: [Account].self)
        do {
            let (c, a) = try await (cats, accts)
            categories = c
            accounts = a
            if selectedAccount == nil { selectedAccount = a.first }
        } catch {}
    }

    func save() async -> Bool {
        amountError = nil; categoryError = nil; accountError = nil; error = nil; budgetExceeded = nil

        guard amount > 0             else { amountError = "Amount must be greater than 0"; return false }
        guard let cat = selectedCategory else { categoryError = "Please select a category"; return false }
        guard let acc = selectedAccount  else { accountError = "Please select an account";  return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.send(
                Endpoint.Transactions.create(
                    accountID: acc.id,
                    categoryID: cat.id,
                    amount: amount,
                    currency: currency,
                    note: note.isEmpty ? nil : note,
                    date: date,
                    type: type.rawValue
                ),
                as: CreateTransactionResponse.self
            )
            budgetExceeded = response.budgetExceeded
            return true
        } catch let e as APIError {
            if case .validation(let fields) = e {
                amountError = fields["amount"]
                categoryError = fields["category_id"]
                accountError = fields["account_id"]
            } else {
                error = e
            }
            return false
        } catch {
            self.error = .network
            return false
        }
    }

    var filteredCategories: [Category] {
        categories.filter { $0.type.rawValue == type.rawValue }
    }
}
