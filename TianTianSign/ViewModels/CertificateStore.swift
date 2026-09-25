//
//  CertificateStore.swift
//  TianTianSign
//
//  从 .p12 文件解析证书信息，密码存 Keychain
//

import Foundation
import Security
import SwiftUI

enum CertificateImporterError: Error {
    case badPassword
    case invalidP12
    case importFailed(String)
}

struct CertificateImporter {

    /// 用密码尝试解析 p12，返回证书的可读信息（不真正导入钥匙串）
    static func inspect(p12 url: URL, password: String) throws -> SigningCertificate {
        let data = try Data(contentsOf: url)

        // 用 SecPKCS12Import 解密，失败即密码错 / 文件坏
        var items: CFArray?
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let dict = array.first,
              let _ = dict[kSecImportItemIdentity as String] else {
            throw CertificateImporterError.importFailed("SecPKCS12Import 失败，status=\(status)")
        }

        // TODO: 从 SecIdentity 里取 SecCertificate，再 copy 出
        // commonName / teamID / serialNumber / validity / cert type
        // 这里用占位值保证编译通过；真实实现见 docs/architecture.md
        let now = Date()
        return SigningCertificate(
            id: UUID(),
            p12URL: url,
            passwordHint: String(password.prefix(1)) + "••••",
            commonName: "Apple Development: Example (TEAMID)",
            teamID: "TEAMID",
            teamName: "Example Team",
            validFrom: now,
            validUntil: Calendar.current.date(byAdding: .year, value: 1, to: now)!,
            certType: .development,
            serialNumber: "00AABBCCDD"
        )
    }

    /// 把密码安全地存进 Keychain（kSecClassGenericPassword）
    static func storePassword(_ password: String, forCertificateID id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func readPassword(forCertificateID id: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
