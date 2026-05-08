import SwiftUI

@main
struct FinTrackIOSApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .task { await env.authService.bootstrap() }
        }
    }
}
