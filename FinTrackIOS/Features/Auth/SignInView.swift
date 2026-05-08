import SwiftUI

struct SignInView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppCoordinator.self) private var coordinator

    var onCreateAccount: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: APIError?
    @State private var emailError: String?
    @State private var passwordError: String?

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: FTSpacing.s8) {
                    // Logo
                    VStack(spacing: FTSpacing.s2) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(FTColor.primary)
                        Text("FinTrack")
                            .font(FTTypography.headingLG)
                            .foregroundStyle(FTColor.primary)
                    }

                    Text("Welcome back.")
                        .font(FTTypography.displayLG)
                        .foregroundStyle(FTColor.textPrimary)

                    VStack(spacing: FTSpacing.s4) {
                        FTTextField(label: "Email", placeholder: "you@example.com", text: $email,
                                    keyboardType: .emailAddress, errorMessage: emailError)

                        FTTextField(label: "Password", placeholder: "••••••••", text: $password,
                                    isSecure: true, errorMessage: passwordError)

                        HStack {
                            Spacer()
                            Button("Forgot password?") {}
                                .font(FTTypography.bodyMD)
                                .foregroundStyle(FTColor.primary)
                        }
                    }

                    if let error {
                        FTErrorBanner(message: error.userMessage)
                    }
                }
                .padding(.horizontal, FTSpacing.s4)

                Spacer()

                VStack(spacing: FTSpacing.s3) {
                    FTButton("Sign in", isLoading: isLoading) {
                        Task { await signIn() }
                    }
                    .padding(.horizontal, FTSpacing.s4)

                    Button("New here? Create an account") {
                        onCreateAccount?()
                        coordinator.showSignIn = false
                    }
                    .font(FTTypography.bodyMD)
                    .foregroundStyle(FTColor.primary)
                }
                .padding(.bottom, FTSpacing.s8)
            }
        }
    }

    private func signIn() async {
        emailError = nil; passwordError = nil; error = nil

        guard !email.isEmpty else { emailError = "Email is required"; return }
        guard !password.isEmpty else { passwordError = "Password is required"; return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await env.authService.signIn(email: email, password: password)
        } catch let apiError as APIError {
            if case .validation(let fields) = apiError {
                emailError = fields["email"]
                passwordError = fields["password"]
            } else {
                error = apiError
            }
        } catch {
            self.error = .network
        }
    }
}

#Preview {
    SignInView()
        .environment(AppEnvironment())
        .environment(AppCoordinator())
}
