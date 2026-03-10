import Foundation
import Supabase
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client: SupabaseClient

    private init() {
        // Supabase credentials — loaded from Info.plist or hardcoded for development
        // In production, these come from the app's configuration
        let url = URL(string:
            Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? "https://your-project.supabase.co"
        )!
        let anonKey =
            Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
            ?? "your-anon-key"

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)

        // Check for existing session on launch
        Task { await restoreSession() }
    }

    // MARK: - Public API

    /// The current Supabase client (for other services to use)
    var supabaseClient: SupabaseClient { client }

    /// Current user's access token for API calls
    var accessToken: String? {
        get async {
            try? await client.auth.session.accessToken
        }
    }

    /// Current user ID
    var userId: String? {
        get async {
            try? await client.auth.session.user.id.uuidString
        }
    }

    // MARK: - Auth Actions

    func signUp(email: String, password: String, fullName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: fullName.map { ["full_name": .string($0)] } ?? [:]
            )

            // Check if email confirmation is required
            if response.session != nil {
                updateLocalProfile(email: email, tier: .free)
                isSignedIn = true
            } else {
                errorMessage = "Check your email to confirm your account."
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[Caspr] Sign up error: \(error)")
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            updateLocalProfile(email: session.user.email ?? email, tier: .free)
            await fetchProfileTier()
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
            print("[Caspr] Sign in error: \(error)")
        }

        isLoading = false
    }

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            updateLocalProfile(email: session.user.email ?? "", tier: .free)
            await fetchProfileTier()
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
            print("[Caspr] Apple sign in error: \(error)")
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("[Caspr] Sign out error: \(error)")
        }

        UserProfile.shared.isSignedIn = false
        UserProfile.shared.email = nil
        UserProfile.shared.tier = .free
        isSignedIn = false
    }

    // MARK: - Session Management

    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            updateLocalProfile(email: session.user.email ?? "", tier: .free)
            await fetchProfileTier()
            isSignedIn = true
            print("[Caspr] Session restored for \(session.user.email ?? "unknown")")
        } catch {
            // No valid session — user is signed out
            isSignedIn = false
            print("[Caspr] No active session")
        }
    }

    private func fetchProfileTier() async {
        do {
            let userId = try await client.auth.session.user.id

            struct ProfileRow: Decodable {
                let tier: String
                let cloud_minutes_used: Int
                let cloud_minutes_limit: Int
            }

            let profile: ProfileRow = try await client
                .from("profiles")
                .select("tier, cloud_minutes_used, cloud_minutes_limit")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let tier = SubscriptionTier(rawValue: profile.tier) ?? .free
            UserProfile.shared.tier = tier
        } catch {
            print("[Caspr] Failed to fetch profile tier: \(error)")
        }
    }

    private func updateLocalProfile(email: String, tier: SubscriptionTier) {
        UserProfile.shared.isSignedIn = true
        UserProfile.shared.email = email
        UserProfile.shared.tier = tier
    }
}
