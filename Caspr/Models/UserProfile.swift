import Foundation

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
    case team
}

@MainActor
final class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var isSignedIn: Bool {
        didSet { UserDefaults.standard.set(isSignedIn, forKey: "isSignedIn") }
    }

    @Published var email: String? {
        didSet { UserDefaults.standard.set(email, forKey: "userEmail") }
    }

    @Published var tier: SubscriptionTier {
        didSet { UserDefaults.standard.set(tier.rawValue, forKey: "userTier") }
    }

    private init() {
        self.isSignedIn = UserDefaults.standard.bool(forKey: "isSignedIn")
        self.email = UserDefaults.standard.string(forKey: "userEmail")
        let tierRaw = UserDefaults.standard.string(forKey: "userTier") ?? "free"
        self.tier = SubscriptionTier(rawValue: tierRaw) ?? .free
    }
}
