import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showSignOutConfirm = false
    @State private var showImportCSV = false
    @State private var showExportCSV = false

    private var userEmail: String {
        if case .signedIn(let user) = env.authService.state { return user.email }
        return "—"
    }

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            List {
                // Account section
                Section("Account") {
                    LabeledContent("Email", value: userEmail)
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textPrimary)

                    LabeledContent("Base currency", value: env.preferences.baseCurrency)
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textPrimary)
                }
                .listRowBackground(FTColor.surface)

                // Categories
                Section("Manage") {
                    NavigationLink(destination: CategoriesManagementView()) {
                        Label("Categories", systemImage: "tag")
                    }
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.textPrimary)

                    NavigationLink(destination: SavingGoalsView()) {
                        Label("Saving Goals", systemImage: "flag")
                    }
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.textPrimary)
                }
                .listRowBackground(FTColor.surface)

                // Data
                Section("Data") {
                    Button {
                        showImportCSV = true
                    } label: {
                        Label("Import CSV", systemImage: "arrow.down.doc")
                            .foregroundStyle(FTColor.textPrimary)
                    }

                    Button {
                        showExportCSV = true
                    } label: {
                        Label("Export CSV", systemImage: "arrow.up.doc")
                            .foregroundStyle(FTColor.textPrimary)
                    }
                }
                .font(FTTypography.bodyMD)
                .listRowBackground(FTColor.surface)

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { env.preferences.colorScheme },
                        set: { env.preferences.colorScheme = $0 }
                    )) {
                        Text("System").tag(ColorScheme?.none)
                        Text("Light").tag(ColorScheme?.some(.light))
                        Text("Dark").tag(ColorScheme?.some(.dark))
                    }
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.textPrimary)
                }
                .listRowBackground(FTColor.surface)

                // About
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textPrimary)

                    LabeledContent("Language", value: Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "English")
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textSecondary)
                }
                .listRowBackground(FTColor.surface)

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(FTColor.danger)
                    }
                    .font(FTTypography.bodyMD)
                }
                .listRowBackground(FTColor.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await env.authService.signOut() }
            }
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
        .sheet(isPresented: $showImportCSV) {
            CSVImportView()
        }
        .sheet(isPresented: $showExportCSV) {
            CSVExportView()
        }
        .preferredColorScheme(env.preferences.colorScheme)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppEnvironment())
    }
}
