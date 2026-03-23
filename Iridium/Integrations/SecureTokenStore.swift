//
//  SecureTokenStore.swift
//  Iridium
//
//  Keychain wrapper for integration API tokens.
//  Each integration gets a namespaced Keychain entry.
//

import Foundation
import OSLog
import Security

final class SecureTokenStore: @unchecked Sendable {
    private static let service = "cicm.Iridium.Integrations"

    /// Saves a token for an integration.
    func setToken(_ token: String, for integrationID: String) -> Bool {
        // Delete existing first
        deleteToken(for: integrationID)

        guard let data = token.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: integrationID,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.integrations.error("Failed to save token for \(integrationID): \(status)")
        }
        return status == errSecSuccess
    }

    /// Retrieves a token for an integration.
    func token(for integrationID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: integrationID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Deletes a token for an integration.
    @discardableResult
    func deleteToken(for integrationID: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: integrationID,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Checks if a token exists for an integration.
    func hasToken(for integrationID: String) -> Bool {
        token(for: integrationID) != nil
    }
}
