import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var coordinator = AppCoordinator()

    var body: some View {
        switch env.authService.state {
        case .unknown:
            splashView
        case .signedOut:
            if coordinator.showSignIn || env.preferences.hasCompletedOnboarding {
                SignInView(onCreateAccount: { coordinator.showSignIn = false })
                    .environment(coordinator)
            } else {
                OnboardingFlowView()
                    .environment(coordinator)
            }
        case .signedIn:
            MainTabView()
        }
    }

    private var splashView: some View {
        ZStack {
            FTColor.bg.ignoresSafeArea()
            VStack(spacing: FTSpacing.s3) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(FTColor.primary)
                ProgressView()
                    .tint(FTColor.primary)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment())
}
