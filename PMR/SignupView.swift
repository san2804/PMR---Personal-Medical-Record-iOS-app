import SwiftUI
import AuthenticationServices
import LocalAuthentication

// MARK: - SignupView
struct SignupView: View {
    // Form fields
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var acceptedTerms: Bool = false

    // UI state
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // White background
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header / Logo
                    VStack(spacing: 12) {
                        Image("PMRLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 84, height: 84)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)

                        Text("Create your account")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundColor(.black)

                        Text("Store and access your medical records securely")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 36)

                    // Card container
                    VStack(spacing: 16) {
                        PMRTextField(title: "Full name", text: $fullName, icon: "person")

                        PMRTextField(title: "Email", text: $email, icon: "envelope", keyboard: .emailAddress, textContentType: .emailAddress)

                        // Password field with strength meter
                        VStack(spacing: 8) {
                            PMRSecureField(title: "Password", text: $password, icon: "lock")
                            PasswordStrengthView(password: password)
                        }

                        PMRSecureField(title: "Confirm password", text: $confirmPassword, icon: "lock.fill")

                        Toggle(isOn: $acceptedTerms) {
                            Text("I agree to the Terms & Privacy Policy")
                                .font(.footnote)
                                .foregroundColor(.black)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))

                        if let error = errorMessage, !error.isEmpty {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: signUp) {
                            HStack(spacing: 8) {
                                if isLoading { ProgressView().tint(.white) }
                                Text(isLoading ? "Creating account…" : "Create account")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PMRPrimaryButtonStyle())
                        .disabled(!formValid || isLoading)
                        .opacity(!formValid || isLoading ? 0.6 : 1)

                        // Divider
                        HStack {
                            Rectangle().fill(.gray.opacity(0.3)).frame(height: 1)
                            Text("or")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Rectangle().fill(.gray.opacity(0.3)).frame(height: 1)
                        }

                        // Sign in with Apple
                        SignInWithAppleButtonRepresentable(type: .signUp, style: .black)
                            .frame(height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityLabel("Sign up with Apple")
                    }
                    .padding(22)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .gray.opacity(0.25), radius: 18, x: 0, y: 10)
                    .padding(.horizontal)

                    // Footer: already have account
                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                            .font(.footnote)
                        Button("Sign in") { dismiss() }
                            .foregroundColor(.blue)
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onChange(of: email) { _ in errorMessage = nil }
        .onChange(of: password) { _ in errorMessage = nil }
        .onChange(of: confirmPassword) { _ in errorMessage = nil }
    }

    // MARK: - Validation
    private var formValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.isValidEmail &&
        passwordValid &&
        (password == confirmPassword) &&
        acceptedTerms
    }

    private var passwordValid: Bool {
        // Example policy: >= 8 chars, at least 1 number and 1 letter
        let lengthOK = password.count >= 8
        let hasNumber = password.range(of: #".*[0-9].*"#, options: .regularExpression) != nil
        let hasLetter = password.range(of: #".*[A-Za-z].*"#, options: .regularExpression) != nil
        return lengthOK && hasNumber && hasLetter
    }

    // MARK: - Actions
    private func signUp() {
        guard formValid else {
            errorMessage = "Please complete all fields correctly and accept the terms."
            return
        }
        errorMessage = nil
        isLoading = true

        // TODO: Replace with your auth service call (CloudKit / custom backend)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            // On success, navigate to the app's main screen
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthView: View {
    let password: String

    private var score: Int {
        var s = 0
        if password.count >= 8 { s += 1 }
        if password.range(of: #".*[0-9].*"#, options: .regularExpression) != nil { s += 1 }
        if password.range(of: #".*[A-Z].*"#, options: .regularExpression) != nil { s += 1 }
        if password.range(of: #".*[a-z].*"#, options: .regularExpression) != nil { s += 1 }
        if password.range(of: #".*[^A-Za-z0-9].*"#, options: .regularExpression) != nil { s += 1 }
        return s
    }

    private var label: String {
        switch score {
        case 0...1: return "Very weak"
        case 2: return "Weak"
        case 3: return "Fair"
        case 4: return "Strong"
        default: return "Very strong"
        }
    }

    private var barFill: Double { Double(score) / 5.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 6)
                    .fill(score >= 4 ? Color.green : (score >= 3 ? Color.orange : Color.red))
                    .frame(width: max(12, barFillWidth), height: 8)
                    .animation(.easeInOut(duration: 0.2), value: score)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    private var barFillWidth: CGFloat {
        // Assume typical card width minus padding
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 64
        return maxWidth * barFill
    }
}

// MARK: - Reusable Controls
// If you already defined PMRTextField and PMRSecureField in your project, remove these duplicates.
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
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.gray.opacity(0.1)))
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
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .foregroundColor(.black)
            .tint(.blue)
            .submitLabel(.next)

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundColor(.gray)
            }
            .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.gray.opacity(0.1)))
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
    NavigationStack {
        SignupView()
    }
}
