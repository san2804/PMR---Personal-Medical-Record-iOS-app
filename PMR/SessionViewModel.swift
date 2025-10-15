import Foundation
import Combine
import FirebaseAuth

final class SessionViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = (Auth.auth().currentUser != nil)
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = (user != nil)
            }
        }
    }

    deinit {
        if let h = handle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }

    func logout() {
        do { try Auth.auth().signOut() } catch { print("Signout error:", error) }
    }
}
