import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting = false
    @State private var isLoading = false
    @State private var result: CSVImportResult?
    @State private var error: APIError?
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                VStack(spacing: FTSpacing.s6) {
                    Spacer()

                    VStack(spacing: FTSpacing.s4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(FTColor.textTertiary)

                        VStack(spacing: FTSpacing.s2) {
                            Text("Import transactions")
                                .font(FTTypography.headingLG)
                                .foregroundStyle(FTColor.textPrimary)
                            Text("Select a CSV file. Column detection is automatic — no mapping needed.")
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, FTSpacing.s6)
                        }
                    }

                    if let result {
                        FTCard {
                            VStack(spacing: FTSpacing.s3) {
                                HStack {
                                    Label("\(result.imported) imported", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(FTColor.income)
                                    Spacer()
                                    if result.failed > 0 {
                                        Label("\(result.failed) failed", systemImage: "xmark.circle")
                                            .foregroundStyle(FTColor.danger)
                                    }
                                }
                                .font(FTTypography.bodyMD)

                                if let errors = result.errors, !errors.isEmpty {
                                    ForEach(errors.prefix(3), id: \.self) { msg in
                                        Text("• \(msg)")
                                            .font(FTTypography.bodySM)
                                            .foregroundStyle(FTColor.textSecondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(FTSpacing.s4)
                        }
                        .padding(.horizontal, FTSpacing.s4)
                    }

                    if let error {
                        FTErrorBanner(message: error.userMessage)
                            .padding(.horizontal, FTSpacing.s4)
                    }

                    Spacer()

                    VStack(spacing: FTSpacing.s3) {
                        FTButton("Choose CSV file", style: .secondary, isLoading: isLoading) {
                            showFilePicker = true
                        }
                        .padding(.horizontal, FTSpacing.s4)

                        if result != nil {
                            FTButton("Done", action: { dismiss() })
                                .padding(.horizontal, FTSpacing.s4)
                        }
                    }
                    .padding(.bottom, FTSpacing.s8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Import CSV").font(FTTypography.headingMD)
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.commaSeparatedText]) { picked in
                switch picked {
                case .success(let url): Task { await importFile(url) }
                case .failure(let err): error = .unknown(code: "file_error", message: err.localizedDescription)
                }
            }
        }
    }

    private func importFile(_ url: URL) async {
        isLoading = true; error = nil; result = nil
        defer { isLoading = false }

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            result = try await env.apiClient.uploadCSV(at: url)
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }
}

struct CSVExportView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var error: APIError?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.bg.ignoresSafeArea()

                VStack(spacing: FTSpacing.s6) {
                    Spacer()

                    VStack(spacing: FTSpacing.s4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(FTColor.textTertiary)

                        VStack(spacing: FTSpacing.s2) {
                            Text("Export transactions")
                                .font(FTTypography.headingLG)
                                .foregroundStyle(FTColor.textPrimary)
                            Text("Export all your transactions as a CSV file.")
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    if let error {
                        FTErrorBanner(message: error.userMessage)
                            .padding(.horizontal, FTSpacing.s4)
                    }

                    Spacer()

                    FTButton("Export all transactions", isLoading: isExporting) {
                        Task { await export() }
                    }
                    .padding(.horizontal, FTSpacing.s4)
                    .padding(.bottom, FTSpacing.s8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(FTColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Export CSV").font(FTTypography.headingMD)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func export() async {
        isExporting = true; error = nil
        defer { isExporting = false }

        do {
            let data = try await env.apiClient.sendData(Endpoint.Transactions.export())
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("fintrack_export_\(Int(Date().timeIntervalSince1970)).csv")
            try data.write(to: tempURL)
            exportedURL = tempURL
            showShareSheet = true
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .network
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
