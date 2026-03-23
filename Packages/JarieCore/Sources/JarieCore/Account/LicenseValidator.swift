import Foundation
import CryptoKit
import os

/// License validation state
public enum LicenseState: Sendable, Equatable {
    case valid(UserTier)
    case grace(tier: UserTier, daysRemaining: Int)
    case expired
    case noLicense
}

/// Validates license using HMAC-signed server timestamps.
/// 7-day offline grace period. Clock rollback detection via Keychain.
/// See tech-architecture.md Section 6 (WARNING — License Offline Grace).
public struct LicenseValidator: Sendable {
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "LicenseValidator")
    private let keychain: KeychainStoring

    /// Maximum days a license is valid without server revalidation
    private static let gracePeriodDays = 7

    public init(keychain: KeychainStoring = LiveKeychainStore()) {
        self.keychain = keychain
    }

    /// Validate the current license state
    public func validate() async -> LicenseState {
        // 1. Check for cached license in Keychain
        guard let cached = loadCachedLicense() else {
            return .noLicense
        }

        // 2. Clock rollback detection: current time must be >= last verified time
        if let lastVerified = loadLastVerifiedDate(), lastVerified > Date() {
            logger.warning("Clock rollback detected — license treated as expired")
            return .expired
        }

        // 3. Check if cached license is within grace period
        let age = Date().timeIntervalSince(cached.validatedAt)
        let ageDays = Int(age / 86400)

        if ageDays <= Self.gracePeriodDays {
            // Within grace period — try server revalidation
            do {
                let fresh = try await fetchLicenseFromServer()
                cache(fresh)
                saveLastVerifiedDate()
                return .valid(fresh.tier)
            } catch {
                // Server unreachable — use cached
                let remaining = Self.gracePeriodDays - ageDays
                if remaining > 0 {
                    return .grace(tier: cached.tier, daysRemaining: remaining)
                } else {
                    return .expired
                }
            }
        }

        // 4. Grace period elapsed
        return .expired
    }

    // MARK: - Server Communication (Phase 1.5A stub)

    private func fetchLicenseFromServer() async throws -> CachedLicense {
        // TODO: Phase 1.5A — call Supabase license validation endpoint
        // Returns HMAC-signed {validUntil, tier, signature}
        // Client verifies HMAC before trusting
        throw LicenseError.serverUnavailable
    }

    // MARK: - Keychain Cache

    struct CachedLicense: Sendable {
        let tier: UserTier
        let validatedAt: Date
        let signature: String // HMAC signature from server
    }

    private func loadCachedLicense() -> CachedLicense? {
        guard let timestampStr = try? keychain.read(.licenseTimestamp),
              let timestamp = Double(timestampStr),
              let signature = try? keychain.read(.licenseSignature) else {
            return nil
        }

        // Determine tier from stored data
        // TODO: Phase 1.5A — decode tier from signed payload
        let tier: UserTier = .byok // Placeholder

        return CachedLicense(
            tier: tier,
            validatedAt: Date(timeIntervalSince1970: timestamp),
            signature: signature
        )
    }

    private func cache(_ license: CachedLicense) {
        let timestamp = String(license.validatedAt.timeIntervalSince1970)
        try? keychain.save(timestamp, for: .licenseTimestamp)
        try? keychain.save(license.signature, for: .licenseSignature)
    }

    private func loadLastVerifiedDate() -> Date? {
        guard let str = try? keychain.read(.lastVerifiedAt),
              let interval = Double(str) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private func saveLastVerifiedDate() {
        let now = String(Date().timeIntervalSince1970)
        try? keychain.save(now, for: .lastVerifiedAt)
    }
}

public enum LicenseError: LocalizedError {
    case serverUnavailable
    case invalidSignature
    case expired

    public var errorDescription: String? {
        switch self {
        case .serverUnavailable: "License server unavailable"
        case .invalidSignature: "License signature invalid"
        case .expired: "License expired"
        }
    }
}
