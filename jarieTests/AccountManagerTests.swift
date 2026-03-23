import Testing
import Foundation
@testable import JarieCore

struct AccountManagerTests {

    // MARK: - AccountState

    @Test func accountStateSignedOutDefaults() {
        let state = AccountState.signedOut
        #expect(state.isSignedIn == false)
        #expect(state.userId == nil)
        #expect(state.tier == .none)
    }

    @Test func accountStateSignedInProperties() {
        let state = AccountState(
            auth: .signedIn(userId: "user-123", email: "test@example.com"),
            tier: .byok
        )
        #expect(state.isSignedIn == true)
        #expect(state.userId == "user-123")
        #expect(state.tier == .byok)
    }

    @Test func accountStateSignedOutUserId() {
        let state = AccountState(auth: .signedOut, tier: .none)
        #expect(state.userId == nil)
    }

    @Test func accountStateAiIncludedTier() {
        let state = AccountState(
            auth: .signedIn(userId: "u-456", email: "pro@example.com"),
            tier: .aiIncluded
        )
        #expect(state.tier == .aiIncluded)
        #expect(state.isSignedIn == true)
    }

    // MARK: - AccountManager

    @MainActor
    @Test func initialStateIsSignedOut() throws {
        // Ensure no cached auth token
        try? KeychainStore.delete(.authToken)

        let manager = AccountManager()
        #expect(manager.state.isSignedIn == false)
        #expect(manager.state.tier == .none)
    }

    @MainActor
    @Test func signOutClearsState() throws {
        try? KeychainStore.delete(.authToken)

        let manager = AccountManager()
        // Manually set a signed-in state via updateTier to change tier
        manager.updateTier(.byok)
        #expect(manager.state.tier == .byok)

        manager.signOut()
        #expect(manager.state.isSignedIn == false)
        #expect(manager.state.tier == .none)
    }

    @MainActor
    @Test func updateTierChangesTier() throws {
        try? KeychainStore.delete(.authToken)

        let manager = AccountManager()
        #expect(manager.state.tier == .none)

        manager.updateTier(.byok)
        #expect(manager.state.tier == .byok)

        manager.updateTier(.aiIncluded)
        #expect(manager.state.tier == .aiIncluded)

        manager.updateTier(.none)
        #expect(manager.state.tier == .none)
    }

    @MainActor
    @Test func updateTierPreservesAuthState() throws {
        try? KeychainStore.delete(.authToken)

        let manager = AccountManager()
        // Initial state is signedOut; updateTier should preserve auth
        manager.updateTier(.byok)

        #expect(manager.state.isSignedIn == false)
        #expect(manager.state.tier == .byok)
    }

    // MARK: - UserTier

    @Test func userTierRawValues() {
        #expect(UserTier.none.rawValue == "none")
        #expect(UserTier.byok.rawValue == "byok")
        #expect(UserTier.aiIncluded.rawValue == "aiIncluded")
    }

    @Test func userTierCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for tier in [UserTier.none, .byok, .aiIncluded] {
            let data = try encoder.encode(tier)
            let decoded = try decoder.decode(UserTier.self, from: data)
            #expect(decoded == tier)
        }
    }

    // MARK: - AccountError

    @Test func accountErrorDescriptions() {
        #expect(AccountError.notAuthenticated.errorDescription == "Not signed in")
        #expect(AccountError.notImplemented.errorDescription == "Auth not yet implemented — requires Supabase setup")
        #expect(AccountError.tokenExpired.errorDescription == "Auth token expired")
    }

    // MARK: - AuthState

    @Test func authStateSignedOut() {
        let state = AuthState.signedOut
        if case .signedOut = state {
            // pass
        } else {
            Issue.record("Expected .signedOut")
        }
    }

    @Test func authStateSignedIn() {
        let state = AuthState.signedIn(userId: "abc", email: "abc@test.com")
        if case .signedIn(let id, let email) = state {
            #expect(id == "abc")
            #expect(email == "abc@test.com")
        } else {
            Issue.record("Expected .signedIn")
        }
    }
}
