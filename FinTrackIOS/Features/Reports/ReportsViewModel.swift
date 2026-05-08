import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class ReportsViewModel {
    private(set) var report: ReportData?
    private(set) var isLoading = false
    var error: APIError?
    var period: BudgetPeriod = .monthly
    var referenceDate = Date()

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let endpoint: Endpoint
            switch period {
            case .monthly:
                let month = DateFormatter.monthParam.string(from: referenceDate)
                endpoint = Endpoint.Reports.monthly(month: month)
            case .weekly:
                let weekOf = DateFormatter.weekOf.string(from: referenceDate)
                endpoint = Endpoint.Reports.weekly(weekOf: weekOf)
            }
            report = try await apiClient.send(endpoint, as: ReportData.self)
        } catch let e as APIError {
            error = e
            Log.ui.error("Reports load error: \(e)")
        } catch {
            self.error = .network
        }
    }

    func stepPeriod(by delta: Int) {
        let cal = Calendar.current
        switch period {
        case .monthly:
            referenceDate = cal.date(byAdding: .month, value: delta, to: referenceDate) ?? referenceDate
        case .weekly:
            referenceDate = cal.date(byAdding: .weekOfYear, value: delta, to: referenceDate) ?? referenceDate
        }
        Task { await load() }
    }

    var periodLabel: String {
        switch period {
        case .monthly: return DateFormatter.monthYear.string(from: referenceDate)
        case .weekly:
            let end = Calendar.current.date(byAdding: .day, value: 6, to: referenceDate) ?? referenceDate
            return "\(DateFormatter.display.string(from: referenceDate)) – \(DateFormatter.display.string(from: end))"
        }
    }
}
