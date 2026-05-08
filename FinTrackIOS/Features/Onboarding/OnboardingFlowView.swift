import SwiftUI

struct OnboardingFlowView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(AppCoordinator.self) private var coordinator

    @State private var page = 0
    @State private var selectedCurrency = "KZT"

    var body: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()

            switch page {
            case 0:
                WelcomePage(
                    onGetStarted: { withAnimation { page = 1 } },
                    onSignIn: { coordinator.showSignIn = true }
                )
            case 1:
                CurrencyPickPage(
                    selected: $selectedCurrency,
                    onContinue: { withAnimation { page = 2 } }
                )
            default:
                OnboardingSignUpPage(
                    baseCurrency: selectedCurrency,
                    onSignIn: { coordinator.showSignIn = true }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: page)
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: FTSpacing.s6) {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 96, weight: .ultraLight))
                    .foregroundStyle(FTColor.primary)

                VStack(spacing: FTSpacing.s2) {
                    Text("Track your money,\ncalmly.")
                        .font(FTTypography.displayLG)
                        .foregroundStyle(FTColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("FinTrack helps you see where your money goes — without the jargon.")
                        .font(FTTypography.bodyLG)
                        .foregroundStyle(FTColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FTSpacing.s6)
                }
            }

            Spacer()

            VStack(spacing: FTSpacing.s3) {
                FTButton("Get started", action: onGetStarted)
                    .padding(.horizontal, FTSpacing.s4)

                Button("I already have an account", action: onSignIn)
                    .font(FTTypography.bodyLG)
                    .foregroundStyle(FTColor.primary)
            }
            .padding(.bottom, FTSpacing.s8)
        }
    }
}

// MARK: - Page 2: Currency Pick

private struct CurrencyPickPage: View {
    @Binding var selected: String
    let onContinue: () -> Void

    private let options: [(code: String, symbol: String, name: String)] = [
        ("KZT", "₸", "Kazakhstani Tenge"),
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: FTSpacing.s2) {
                Text("What's your home currency?")
                    .font(FTTypography.displayLG)
                    .foregroundStyle(FTColor.textPrimary)

                Text("We'll convert all your transactions to this currency for reports.")
                    .font(FTTypography.bodyLG)
                    .foregroundStyle(FTColor.textSecondary)
            }
            .padding(.horizontal, FTSpacing.s4)
            .padding(.top, FTSpacing.s12)

            Spacer()

            VStack(spacing: FTSpacing.s3) {
                ForEach(options, id: \.code) { opt in
                    CurrencyCard(code: opt.code, symbol: opt.symbol, name: opt.name, isSelected: selected == opt.code) {
                        selected = opt.code
                    }
                }
            }
            .padding(.horizontal, FTSpacing.s4)

            Spacer()

            FTButton("Continue", action: onContinue)
                .padding(.horizontal, FTSpacing.s4)
                .padding(.bottom, FTSpacing.s8)
        }
    }
}

private struct CurrencyCard: View {
    let code: String
    let symbol: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FTSpacing.s4) {
                Text(symbol)
                    .font(FTTypography.displayLG)
                    .foregroundStyle(isSelected ? FTColor.primary : FTColor.textSecondary)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(code)
                        .font(FTTypography.headingMD)
                        .foregroundStyle(FTColor.textPrimary)
                    Text(name)
                        .font(FTTypography.bodyMD)
                        .foregroundStyle(FTColor.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FTColor.primary)
                        .font(.system(size: 22))
                }
            }
            .padding(FTSpacing.s4)
            .background(isSelected ? FTColor.primarySoft : FTColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.lg)
                    .strokeBorder(isSelected ? FTColor.primary : FTColor.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Page 3: Sign Up

private struct OnboardingSignUpPage: View {
    @Environment(AppEnvironment.self) private var env

    let baseCurrency: String
    let onSignIn: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: APIError?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FTSpacing.s6) {
                VStack(alignment: .leading, spacing: FTSpacing.s2) {
                    Text("Create your account.")
                        .font(FTTypography.displayLG)
                        .foregroundStyle(FTColor.textPrimary)
                }
                .padding(.top, FTSpacing.s12)

                VStack(spacing: FTSpacing.s4) {
                    FTTextField(label: "Email", placeholder: "you@example.com", text: $email,
                                keyboardType: .emailAddress, errorMessage: emailError)

                    FTTextField(label: "Password", placeholder: "••••••••", text: $password,
                                isSecure: true, errorMessage: passwordError)

                    FTTextField(label: "Confirm Password", placeholder: "••••••••", text: $confirmPassword,
                                isSecure: true, errorMessage: confirmError)
                }

                if let error {
                    FTErrorBanner(message: error.userMessage)
                }
            }
            .padding(.horizontal, FTSpacing.s4)
        }

        VStack(spacing: FTSpacing.s3) {
            FTButton("Create account", isLoading: isLoading) {
                Task { await signUp() }
            }
            .padding(.horizontal, FTSpacing.s4)

            Button("Already have an account? Sign in", action: onSignIn)
                .font(FTTypography.bodyMD)
                .foregroundStyle(FTColor.primary)
        }
        .padding(.bottom, FTSpacing.s8)
    }

    private func signUp() async {
        emailError = nil; passwordError = nil; confirmError = nil; error = nil

        guard !email.isEmpty else { emailError = "Email is required"; return }
        guard password.count >= 8 else { passwordError = "Password must be at least 8 characters"; return }
        guard password == confirmPassword else { confirmError = "Passwords do not match"; return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await env.authService.signUp(email: email, password: password, baseCurrency: baseCurrency)
            env.preferences.hasCompletedOnboarding = true
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
    OnboardingFlowView()
        .environment(AppEnvironment())
        .environment(AppCoordinator())
}
