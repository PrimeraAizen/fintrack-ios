import SwiftUI
import Charts

struct ReportsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        _ReportsBody(apiClient: env.apiClient)
    }
}

private struct _ReportsBody: View {
    @State private var vm: ReportsViewModel

    init(apiClient: APIClient) {
        _vm = State(wrappedValue: ReportsViewModel(apiClient: apiClient))
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            if vm.isLoading && vm.report == nil {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack(spacing: FTSpacing.s4) {
                        // Period controls
                        Picker("Period", selection: $vm.period) {
                            Text("Weekly").tag(BudgetPeriod.weekly)
                            Text("Monthly").tag(BudgetPeriod.monthly)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, FTSpacing.s4)
                        .onChange(of: vm.period) { _, _ in Task { await vm.load() } }

                        // Period navigation
                        HStack {
                            Button { vm.stepPeriod(by: -1) } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(FTColor.primary)
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()
                            Text(vm.periodLabel)
                                .font(FTTypography.headingMD)
                                .foregroundStyle(FTColor.textPrimary)
                            Spacer()
                            Button { vm.stepPeriod(by: 1) } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(FTColor.primary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, FTSpacing.s2)

                        if let report = vm.report {
                            // Summary card
                            summaryCard(report)
                                .padding(.horizontal, FTSpacing.s4)

                            // Donut chart
                            if !report.byCategory.isEmpty {
                                donutCard(report)
                                    .padding(.horizontal, FTSpacing.s4)
                            }

                            // Trend line
                            if !report.dailyTrend.isEmpty {
                                trendCard(report)
                                    .padding(.horizontal, FTSpacing.s4)
                            }

                            // Top categories
                            topCategoriesList(report)
                                .padding(.horizontal, FTSpacing.s4)
                        } else if vm.error == nil {
                            FTEmptyState(
                                icon: "chart.pie",
                                title: "No data",
                                message: "Add transactions to see your reports."
                            )
                        }
                    }
                    .padding(.vertical, FTSpacing.s4)
                }
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .top) {
            if let error = vm.error {
                FTErrorBanner(message: error.userMessage, retryAction: { Task { await vm.load() } })
                    .padding(FTSpacing.s4)
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Summary Card

    private func summaryCard(_ report: ReportData) -> some View {
        FTCard {
            VStack(spacing: FTSpacing.s3) {
                VStack(spacing: FTSpacing.s1) {
                    Text("Net for \(vm.periodLabel)")
                        .font(FTTypography.label)
                        .foregroundStyle(FTColor.textSecondary)
                    Text(CurrencyFormatter.format(report.net, currency: "KZT"))
                        .font(FTTypography.displayXL)
                        .foregroundStyle(report.net >= 0 ? FTColor.income : FTColor.danger)
                }

                Divider().overlay(FTColor.border)

                HStack {
                    statPair(label: "Income", value: report.totalIncome, color: FTColor.income)
                    Spacer()
                    Divider().frame(height: 28)
                    Spacer()
                    statPair(label: "Expenses", value: report.totalExpense, color: FTColor.textPrimary)
                }
            }
            .padding(FTSpacing.s4)
        }
    }

    private func statPair(label: String, value: Decimal, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(FTTypography.bodySM).foregroundStyle(FTColor.textSecondary)
            Text(CurrencyFormatter.format(value, currency: "KZT"))
                .font(FTTypography.numericMD).foregroundStyle(color)
        }
    }

    // MARK: - Donut Chart

    private func donutCard(_ report: ReportData) -> some View {
        let grandTotal = report.byCategory.map(\.total).reduce(Decimal(0), +)
        return FTCard {
            VStack(spacing: FTSpacing.s4) {
                Text("Spending by category")
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Chart(report.byCategory) { item in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: item.total).doubleValue),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", item.categoryName))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartLegend(.hidden)

                // Legend grid
                let columns = Array(repeating: GridItem(.flexible()), count: 2)
                LazyVGrid(columns: columns, spacing: FTSpacing.s2) {
                    ForEach(Array(report.byCategory.prefix(8).enumerated()), id: \.element.id) { idx, item in
                        let pct = grandTotal > 0 ? Int(NSDecimalNumber(decimal: item.total / grandTotal * 100).intValue) : 0
                        HStack(spacing: FTSpacing.s2) {
                            Circle()
                                .fill(FTColor.categoryPalette[idx % FTColor.categoryPalette.count])
                                .frame(width: 8, height: 8)
                            Text(item.categoryName)
                                .font(FTTypography.bodySM)
                                .foregroundStyle(FTColor.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(pct)%")
                                .font(FTTypography.bodySM)
                                .foregroundStyle(FTColor.textTertiary)
                        }
                    }
                }
            }
            .padding(FTSpacing.s4)
        }
    }

    // MARK: - Trend Line

    private func trendCard(_ report: ReportData) -> some View {
        FTCard {
            VStack(alignment: .leading, spacing: FTSpacing.s3) {
                Text("Spending trend")
                    .font(FTTypography.headingMD)
                    .foregroundStyle(FTColor.textPrimary)

                Chart(report.dailyTrend) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", NSDecimalNumber(decimal: item.expense).doubleValue)
                    )
                    .foregroundStyle(FTColor.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Amount", NSDecimalNumber(decimal: item.expense).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FTColor.primary.opacity(0.18), FTColor.primary.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
                .frame(height: 160)
            }
            .padding(FTSpacing.s4)
        }
    }

    // MARK: - Top Categories

    private func topCategoriesList(_ report: ReportData) -> some View {
        let grandTotal = report.byCategory.map(\.total).reduce(Decimal(0), +)
        return FTCard {
            VStack(spacing: 0) {
                ForEach(Array(report.byCategory.prefix(3).enumerated()), id: \.element.id) { idx, item in
                    let pct = grandTotal > 0 ? Int(NSDecimalNumber(decimal: item.total / grandTotal * 100).intValue) : 0
                    HStack(spacing: FTSpacing.s3) {
                        Text("\(idx + 1)")
                            .font(FTTypography.label)
                            .foregroundStyle(FTColor.textTertiary)
                            .frame(width: 20)

                        Circle()
                            .fill(FTColor.categoryPalette[idx % FTColor.categoryPalette.count])
                            .frame(width: 8, height: 8)

                        Text(item.categoryName)
                            .font(FTTypography.bodyMD)
                            .foregroundStyle(FTColor.textPrimary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(CurrencyFormatter.format(item.total, currency: "KZT"))
                                .font(FTTypography.numericMD)
                                .foregroundStyle(FTColor.textPrimary)
                            Text("\(pct)%")
                                .font(FTTypography.bodySM)
                                .foregroundStyle(FTColor.textSecondary)
                        }
                    }
                    .frame(minHeight: 52)
                    .padding(.horizontal, FTSpacing.s4)

                    if idx < min(2, report.byCategory.count - 1) {
                        Divider().overlay(FTColor.border).padding(.leading, FTSpacing.s4)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportsView()
            .environment(AppEnvironment())
    }
}
