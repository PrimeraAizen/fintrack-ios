import Foundation
import Security

enum KeychainStore {
    private static let service = "kz.diyas.fintrack.tokens"

    enum Key: String {
        case accessToken  = "accessToken"
        case refreshToken = "refreshToken"
    }

    static func write(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingFailed }

        try delete(key)

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }

    static func read(_ key: Key) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }

    @discardableResult
    static func delete(_ key: Key) throws -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osStatus(status)
        }
        return status == errSecSuccess
    }

    static func deleteAll() throws {
        try delete(.accessToken)
        try delete(.refreshToken)
    }
}

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case osStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:   "Failed to encode token data."
        case .decodingFailed:   "Failed to decode token data."
        case .osStatus(let s):  "Keychain error: \(s)"
        }
    }
}
