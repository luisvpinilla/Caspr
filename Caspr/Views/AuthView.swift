import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var auth = AuthService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(DesignTokens.accentPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    LEDIndicatorView(color: DesignTokens.ledPro, size: 6)
                    Text("PRO")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(DesignTokens.ledPro)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DesignTokens.bgHeader)

            Divider().background(DesignTokens.borderSubtle)

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("👻")
                        .font(.system(size: 36))

                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("Sign in to unlock Pro features")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                // Form
                VStack(spacing: 12) {
                    if isSignUp {
                        inputField("Full Name", text: $fullName, icon: "person")
                    }

                    inputField("Email", text: $email, icon: "envelope")

                    passwordField("Password", text: $password)
                }
                .frame(maxWidth: 280)

                // Error message
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.ledRecording)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Submit button
                Button(action: submit) {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(height: 16)
                        } else {
                            Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(2)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 12)
                    .background(DesignTokens.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(DesignTokens.borderSubtle)
                        .frame(height: 1)
                    Text("or")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textMuted)
                    Rectangle()
                        .fill(DesignTokens.borderSubtle)
                        .frame(height: 1)
                }
                .frame(maxWidth: 280)

                // Sign in with Apple
                SignInWithAppleButton(
                    .signIn,
                    onRequest: configureAppleSignIn,
                    onCompletion: handleAppleSignIn
                )
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: 280, maxHeight: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Toggle sign up / sign in
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.accentPrimary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(20)
        }
        .background(DesignTokens.bgApp)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn { dismiss() }
        }
    }

    // MARK: - Components

    private func inputField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textMuted)
                .frame(width: 16)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(12)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
    }

    private func passwordField(_ placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textMuted)
                .frame(width: 16)

            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(12)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func submit() {
        Task {
            if isSignUp {
                await auth.signUp(email: email, password: password, fullName: fullName.isEmpty ? nil : fullName)
            } else {
                await auth.signIn(email: email, password: password)
            }
        }
    }

    // MARK: - Apple Sign In

    @State private var currentNonce: String?

    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let idTokenData = appleCredential.identityToken,
                let idToken = String(data: idTokenData, encoding: .utf8),
                let nonce = currentNonce
            else { return }

            Task {
                await auth.signInWithApple(idToken: idToken, nonce: nonce)
            }

        case .failure(let error):
            print("[Caspr] Apple sign in failed: \(error)")
        }
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256Hash.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// SHA256 using CryptoKit
import CryptoKit

private enum SHA256Hash {
    static func hash(data: Data) -> [UInt8] {
        let digest = CryptoKit.SHA256.hash(data: data)
        return Array(digest)
    }
}
