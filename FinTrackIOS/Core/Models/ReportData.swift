import Foundation

struct ReportData: Decodable, Sendable {
    @StringOrDecimal var totalIncome: Decimal
    @StringOrDecimal var totalExpense: Decimal
    @StringOrDecimal var net: Decimal
    let byCategory: [CategoryBreakdown]
    let dailyTrend: [DailyTrendPoint]
}

struct CategoryBreakdown: Decodable, Identifiable, Sendable {
    let categoryId: UUID
    let categoryName: String
    let categoryType: String
    @StringOrDecimal var total: Decimal
    var id: UUID { categoryId }
}

struct DailyTrendPoint: Decodable, Identifiable, Sendable {
    let date: Date
    @StringOrDecimal var income: Decimal
    @StringOrDecimal var expense: Decimal
    var id: Date { date }
}
