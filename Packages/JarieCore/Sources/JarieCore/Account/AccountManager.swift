import Foundation
import os

/// User tier levels
public enum UserTier: String, Codable, Sendable {
    case none       // No account or expired
    case byok       // $24.99/yr — bring your own key
    case aiIncluded // $19.99/mo — AI proxy included
}

/// Authentication state
public enum AuthState: Sendable {
    case signedOut
    case signedIn(userId: String, email: String)
}

/// Account state combining auth + tier
public struct AccountState: Sendable {
    public let auth: AuthState
    public let tier: UserTier

    public init(auth: AuthState, tier: UserTier) {
        self.auth = auth
        self.tier = tier
    }

    public var isSignedIn: Bool {
        if case .signedIn = auth { return true }
        return false
    }

    public var userId: String? {
        if case .signedIn(let id, _) = auth { return id }
        return nil
    }

    public static let signedOut = AccountState(auth: .signedOut, tier: .none)
}

/// Manages auth state, tier, and account lifecycle.
/// Real Supabase integration deferred to Phase 1.5A — this establishes the interface.
@MainActor
@Observable
public final class AccountManager {
    public private(set) var state: AccountState = .signedOut
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "AccountManager")

    public init() {
        // Restore cached auth state from Keychain on init
        restoreCachedState()
    }

    /// Sign in with Apple — delegates to Supabase Auth (Phase 1.5A)
    public func signInWithApple(identityToken: Data) async throws {
        // TODO: Phase 1.5A — exchange identity token with Supabase Auth
        // For now, this is a stub that demonstrates the interface
        logger.info("SIWA sign-in initiated")
        throw AccountError.notImplemented
    }

    /// Sign in with email/password — delegates to Supabase Auth (Phase 1.5A)
    public func signInWithEmail(_ email: String, password: String) async throws {
        logger.info("Email sign-in initiated for \(email)")
        throw AccountError.notImplemented
    }

    /// Sign out — clears auth tokens and resets state
    public func signOut() {
        try? KeychainStore.delete(.authToken)
        state = .signedOut
        logger.info("User signed out")
    }

    /// Update tier (called after license validation or Stripe webhook)
    public func updateTier(_ tier: UserTier) {
        state = AccountState(auth: state.auth, tier: tier)
        logger.info("Tier updated to \(tier.rawValue)")
    }

    /// Get the current JWT for API calls (Phase 1.5A)
    public func currentJWT() async throws -> String {
        guard let token = try KeychainStore.read(.authToken) else {
            throw AccountError.notAuthenticated
        }
        // TODO: Phase 1.5A — check expiry, refresh if needed
        return token
    }

    // MARK: - Private

    private func restoreCachedState() {
        // Check for cached auth token
        if let token = try? KeychainStore.read(.authToken), !token.isEmpty {
            // TODO: Phase 1.5A — decode JWT to extract userId + email
            // For now, mark as signed in with placeholder
            logger.info("Restored cached auth state")
        }
    }
}

public enum AccountError: LocalizedError {
    case notAuthenticated
    case notImplemented
    case tokenExpired

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Not signed in"
        case .notImplemented: "Auth not yet implemented — requires Supabase setup"
        case .tokenExpired: "Auth token expired"
        }
    }
}
