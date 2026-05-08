import Foundation
import Observation

@MainActor
@Observable
final class TransferViewModel {
    var fromAccount: Account?
    var toAccount: Account?
    var amountText = ""
    var note = ""
    var exchangeRate: ExchangeRate?
    var isLoading = false
    var isFetchingRate = false
    var error: APIError?
    var amountError: String?

    private let apiClient: APIClient
    private let rateCache: ExchangeRateCache
    let accounts: [Account]

    var amount: Decimal { Decimal(string: amountText) ?? 0 }

    var isValid: Bool {
        amount > 0 &&
        fromAccount != nil &&
        toAccount != nil &&
        fromAccount?.id != toAccount?.id
    }

    var convertedAmount: Decimal? {
        guard let rate = exchangeRate, amount > 0 else { return nil }
        return amount * rate.rate
    }

    var currenciesDiffer: Bool {
        fromAccount?.currency != toAccount?.currency &&
        fromAccount?.currency != nil && toAccount?.currency != nil
    }

    init(apiClient: APIClient, rateCache: ExchangeRateCache, accounts: [Account]) {
        self.apiClient = apiClient
        self.rateCache = rateCache
        self.accounts = accounts
        self.fromAccount = accounts.first
        self.toAccount = accounts.count > 1 ? accounts[1] : nil
    }

    func refreshRate() async {
        guard let from = fromAccount, let to = toAccount,
              from.currency != to.currency else {
            exchangeRate = nil
            return
        }
        isFetchingRate = true
        defer { isFetchingRate = false }

        do {
            exchangeRate = try await rateCache.rate(from: from.currency, to: to.currency) {
                try await apiClient.send(
                    Endpoint.ExchangeRates.rate(from: from.currency, to: to.currency),
                    as: ExchangeRate.self
                )
            }
        } catch {
            exchangeRate = nil
        }
    }

    func submit() async -> Bool {
        amountError = nil; error = nil

        guard amount > 0 else { amountError = "Amount must be greater than 0"; return false }
        guard let from = fromAccount, let to = toAccount else { return false }
        guard from.id != to.id else { error = .unknown(code: "same_account", message: "Choose different accounts"); return false }

        isLoading = true
        defer { isLoading = false }

        let dateStr = DateFormatter.weekOf.string(from: Date())
        do {
            try await apiClient.sendVoid(
                Endpoint.Transfers.create(
                    fromAccountID: from.id,
                    toAccountID: to.id,
                    amount: amount,
                    note: note.isEmpty ? nil : note,
                    date: dateStr
                )
            )
            return true
        } catch let e as APIError {
            error = e
            return false
        } catch {
            self.error = .network
            return false
        }
    }
}
