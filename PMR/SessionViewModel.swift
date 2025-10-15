import Foundation
import FirebaseAuth

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = (Auth.auth().currentUser != nil)
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in self.isAuthenticated = (user != nil) }
        }
    }

    deinit { if let h = handle { Auth.auth().removeStateDidChangeListener(h) } }

    func logout() { try? Auth.auth().signOut() }
}
