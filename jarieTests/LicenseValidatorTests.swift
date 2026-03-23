import Testing
import Foundation
@testable import JarieCore

/// In-memory mock for KeychainStoring — no system Keychain access.
final class MockKeychainStore: KeychainStoring, @unchecked Sendable {
    private var store: [String: String] = [:]

    func save(_ value: String, for key: KeychainStore.Key) throws {
        store[key.rawValue] = value
    }

    func read(_ key: KeychainStore.Key) throws -> String? {
        store[key.rawValue]
    }

    func delete(_ key: KeychainStore.Key) throws {
        store.removeValue(forKey: key.rawValue)
    }
}

@Suite(.serialized)
struct LicenseValidatorTests {

    // MARK: - LicenseState enum

    @Test func licenseStateValues() {
        let valid = LicenseState.valid(.byok)
        let grace = LicenseState.grace(tier: .aiIncluded, daysRemaining: 3)
        let expired = LicenseState.expired
        let noLicense = LicenseState.noLicense

        // Equatable conformance
        #expect(valid == LicenseState.valid(.byok))
        #expect(grace == LicenseState.grace(tier: .aiIncluded, daysRemaining: 3))
        #expect(expired == LicenseState.expired)
        #expect(noLicense == LicenseState.noLicense)

        // Different values are not equal
        #expect(valid != expired)
        #expect(grace != noLicense)
        #expect(LicenseState.valid(.byok) != LicenseState.valid(.aiIncluded))
        #expect(LicenseState.grace(tier: .byok, daysRemaining: 3) != LicenseState.grace(tier: .byok, daysRemaining: 5))
    }

    @Test func licenseStateValidCarriesTier() {
        let state = LicenseState.valid(.aiIncluded)
        if case .valid(let tier) = state {
            #expect(tier == .aiIncluded)
        } else {
            Issue.record("Expected .valid state")
        }
    }

    @Test func licenseStateGraceCarriesTierAndDays() {
        let state = LicenseState.grace(tier: .byok, daysRemaining: 5)
        if case .grace(let tier, let days) = state {
            #expect(tier == .byok)
            #expect(days == 5)
        } else {
            Issue.record("Expected .grace state")
        }
    }

    // MARK: - validate() flow (using MockKeychainStore)

    @Test func validateReturnsNoLicenseWhenKeychainEmpty() async throws {
        let mock = MockKeychainStore()
        let validator = LicenseValidator(keychain: mock)
        let result = await validator.validate()
        #expect(result == .noLicense)
    }

    @Test func validateReturnsExpiredOnClockRollback() async throws {
        let mock = MockKeychainStore()

        // Set up a cached license
        let pastTimestamp = String(Date().timeIntervalSince1970 - 3600) // 1 hour ago
        try mock.save(pastTimestamp, for: .licenseTimestamp)
        try mock.save("test-signature", for: .licenseSignature)

        // Set lastVerifiedAt to the future (simulates clock rollback)
        let futureTimestamp = String(Date().timeIntervalSince1970 + 86400) // 24 hours in future
        try mock.save(futureTimestamp, for: .lastVerifiedAt)

        let validator = LicenseValidator(keychain: mock)
        let result = await validator.validate()
        #expect(result == .expired)
    }

    @Test func validateReturnsExpiredWhenGracePeriodElapsed() async throws {
        let mock = MockKeychainStore()

        // Set up a cached license older than 7 days
        let oldTimestamp = String(Date().timeIntervalSince1970 - (8 * 86400)) // 8 days ago
        try mock.save(oldTimestamp, for: .licenseTimestamp)
        try mock.save("test-signature", for: .licenseSignature)

        let validator = LicenseValidator(keychain: mock)
        let result = await validator.validate()
        #expect(result == .expired)
    }

    @Test func validateReturnsGraceWhenWithinPeriod() async throws {
        let mock = MockKeychainStore()

        // Set up a cached license from 2 days ago (within 7-day grace)
        let recentTimestamp = String(Date().timeIntervalSince1970 - (2 * 86400))
        try mock.save(recentTimestamp, for: .licenseTimestamp)
        try mock.save("test-signature", for: .licenseSignature)

        let validator = LicenseValidator(keychain: mock)
        let result = await validator.validate()

        // Server is stubbed to throw .serverUnavailable, so we get grace
        if case .grace(let tier, let days) = result {
            #expect(tier == .byok)
            #expect(days == 5) // 7 - 2 = 5
        } else {
            Issue.record("Expected .grace state, got \(result)")
        }
    }

    // MARK: - LicenseError

    @Test func licenseErrorDescriptions() {
        let serverErr = LicenseError.serverUnavailable
        let sigErr = LicenseError.invalidSignature
        let expErr = LicenseError.expired

        #expect(serverErr.errorDescription == "License server unavailable")
        #expect(sigErr.errorDescription == "License signature invalid")
        #expect(expErr.errorDescription == "License expired")
    }
}
