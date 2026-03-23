import Foundation
import Security
import os

/// Secure storage wrapper around the iOS/macOS Keychain.
/// All items use kSecAttrAccessibleWhenUnlockedThisDeviceOnly — no iCloud Keychain sync.
/// WARNING: BYOK API keys must only be stored here. Never UserDefaults, never logged, never transmitted.
public enum KeychainStore {
    private static let logger = Logger(subsystem: "com.easyberry.jarie", category: "KeychainStore")

    public enum Key: String, Sendable {
        case authToken = "com.easyberry.jarie.authToken"
        case byokAPIKey = "com.easyberry.jarie.byokAPIKey"
        case licenseTimestamp = "com.easyberry.jarie.licenseTimestamp"
        case licenseSignature = "com.easyberry.jarie.licenseSignature"
        case lastVerifiedAt = "com.easyberry.jarie.lastVerifiedAt"
    }

    public enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case readFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed

        public var errorDescription: String? {
            switch self {
            case .saveFailed(let s): "Keychain save failed: \(s)"
            case .readFailed(let s): "Keychain read failed: \(s)"
            case .deleteFailed(let s): "Keychain delete failed: \(s)"
            case .dataConversionFailed: "Keychain data conversion failed"
            }
        }
    }

    public static func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        // Delete existing item first (update pattern)
        try? delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Keychain save failed for \(key.rawValue): \(status)")
            throw KeychainError.saveFailed(status)
        }
    }

    public static func read(_ key: Key) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.readFailed(status)
        }
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        return string
    }

    public static func delete(_ key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Check if a key exists without reading the value
    public static func exists(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: false
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

// MARK: - Protocol for testability

/// Abstraction over Keychain storage to allow mock injection in tests.
public protocol KeychainStoring: Sendable {
    func save(_ value: String, for key: KeychainStore.Key) throws
    func read(_ key: KeychainStore.Key) throws -> String?
    func delete(_ key: KeychainStore.Key) throws
}

/// Production implementation that delegates to the real Keychain.
public struct LiveKeychainStore: KeychainStoring {
    public init() {}

    public func save(_ value: String, for key: KeychainStore.Key) throws {
        try KeychainStore.save(value, for: key)
    }
    public func read(_ key: KeychainStore.Key) throws -> String? {
        try KeychainStore.read(key)
    }
    public func delete(_ key: KeychainStore.Key) throws {
        try KeychainStore.delete(key)
    }
}
