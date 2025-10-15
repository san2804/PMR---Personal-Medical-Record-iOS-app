import SwiftUI
import LocalAuthentication
import FirebaseAuth

// MARK: - LoginView
struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingSignup: Bool = false
    @State private var resetSentBanner: Bool = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo + Title
                VStack(spacing: 12) {
                    Image("PMRLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)

                    Text("Personal Medical Record")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.black)
                    Text("Sign in to continue")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding(.top, 40)

                // Card
                VStack(spacing: 18) {
                    PMRTextField(
                        title: "Email",
                        text: $email,
                        icon: "envelope",
                        keyboard: .emailAddress,
                        textContentType: .username
                    )

                    PMRSecureField(
                        title: "Password",
                        text: $password,
                        icon: "lock"
                    )

                    if let error = errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if resetSentBanner {
                        Text("Password reset email sent.")
                            .font(.footnote)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: signIn) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "Signing In…" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PMRPrimaryButtonStyle())
                    .disabled(!isValid || isLoading)
                    .opacity(!isValid || isLoading ? 0.6 : 1)

                    // Biometrics shortcut (optional; does not replace Firebase login)
                    Button(action: authenticateBiometrics) {
                        Label("Use Face ID", systemImage: "faceid")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PMRSecondaryButtonStyle())
                }
                .padding(22)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .gray.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal)

                // Footer
                HStack(spacing: 6) {
                    Button("Forgot password?") { sendPasswordReset() }
                        .foregroundColor(.gray)
                        .font(.footnote)
                    Text("·").foregroundColor(.gray)
                    Button("Create account") { showingSignup = true }
                        .foregroundColor(.black)
                        .font(.footnote.weight(.semibold))
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingSignup) {
            NavigationStack { SignupView() }
        }
        .onChange(of: email) { _ in errorMessage = nil; resetSentBanner = false }
        .onChange(of: password) { _ in errorMessage = nil }
    }

    // MARK: - Validation & Actions
    private var isValid: Bool {
        email.isValidEmail && password.count >= 6
    }

    private func signIn() {
        guard isValid else {
            errorMessage = "Enter a valid email and a password with 6+ characters."
            return
        }
        errorMessage = nil
        isLoading = true

        Task {
            do {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
                await MainActor.run { isLoading = false }
                // SessionViewModel will switch to Dashboard automatically.
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = (error as NSError).localizedDescription
                }
            }
        }
    }

    private func sendPasswordReset() {
        guard email.isValidEmail else {
            errorMessage = "Enter your email above to receive a reset link."
            return
        }
        errorMessage = nil
        resetSentBanner = false
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run { resetSentBanner = true }
            } catch {
                await MainActor.run { errorMessage = (error as NSError).localizedDescription }
            }
        }
    }

    private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your medical records."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                if !success {
                    DispatchQueue.main.async { self.errorMessage = "Face ID failed. Try again." }
                }
            }
        } else {
            errorMessage = "Biometrics not available on this device."
        }
    }
}

// MARK: - Custom TextFields
struct PMRTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .imageScale(.medium)
                .foregroundColor(.gray)
                .frame(width: 24)

            TextField(title, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(.black)
                .tint(.blue)
                .submitLabel(.next)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct PMRSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String
    @State private var isSecure: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .imageScale(.medium)
                .foregroundColor(.gray)
                .frame(width: 24)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .foregroundColor(.black)
            .tint(.blue)
            .submitLabel(.done)

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Button Styles
struct PMRPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PMRSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
            )
            .foregroundColor(.black)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Email Validation
fileprivate extension String {
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
