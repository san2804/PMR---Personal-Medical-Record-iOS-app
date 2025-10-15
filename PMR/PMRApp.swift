import SwiftUI
import FirebaseCore

@main
struct PMRApp: App {
    @StateObject private var session = SessionViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        if session.isAuthenticated {
            DashboardView()
        } else {
            LoginView()  // <-- no trailing closure
        }
    }
}
