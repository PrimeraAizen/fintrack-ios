import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddTransaction = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)

            NavigationStack { AccountsView() }
                .tabItem { Label("Accounts", systemImage: "creditcard") }
                .tag(1)

            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)

            NavigationStack { BudgetsView() }
                .tabItem { Label("Budgets", systemImage: "chart.bar") }
                .tag(3)

            NavigationStack { ReportsView() }
                .tabItem { Label("Reports", systemImage: "chart.pie") }
                .tag(4)
        }
        .tint(FTColor.primary)
        .onChange(of: selectedTab) { _, new in
            if new == 2 {
                showAddTransaction = true
                selectedTab = 0
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }
}


#Preview {
    MainTabView()
        .environment(AppEnvironment())
}
