//
//  CertificateImporter.swift
//  TianTianSign
//

import Foundation
import Security

enum CertError: Error, LocalizedError {
    case p12Failed(String)
    case profileFailed(String)
    var errorDescription: String? {
        switch self {
        case .p12Failed(let m): return m
        case .profileFailed(let m): return m
        }
    }
}

struct CertificateImporter {

    /// 导入 p12 + mobileprovision 作为一对
    static func `import`(p12 srcURL: URL, profile srcProfileURL: URL, password: String) throws -> SigningCertificate {
        // 1. 验证 p12
        let p12Data = try Data(contentsOf: srcURL)
        var items: CFArray?
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let dict = array.first,
              let identity = dict[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw CertError.p12Failed("p12 密码错误或文件损坏 (code: \(status))")
        }

        var secCert: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &secCert) == errSecSuccess, let cert = secCert else {
            throw CertError.p12Failed("无法读取证书内容")
        }

        let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "未知证书"
        var teamID = ""
        var displayName = summary
        if let r = summary.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            teamID = String(summary[r]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            displayName = summary.replacingOccurrences(of: String(summary[r]), with: "").trimmingCharacters(in: .whitespaces)
        }

        // 2. 解析 mobileprovision
        let profData = try Data(contentsOf: srcProfileURL)
        guard let text = String(data: profData, encoding: .ascii),
              let xmlStart = text.range(of: "<?xml"),
              let xmlEnd = text.range(of: "</plist>") else {
            throw CertError.profileFailed("描述文件格式错误")
        }
        let xml = String(text[xmlStart.lowerBound..<xmlEnd.upperBound])
        guard let plistData = xml.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw CertError.profileFailed("描述文件解析失败")
        }
        let profName = plist["Name"] as? String ?? "描述文件"
        var bundleID = "*"
        if let ent = plist["Entitlements"] as? [String: Any],
           let appID = ent["application-identifier"] as? String {
            let parts = appID.components(separatedBy: ".")
            if parts.count > 1 { bundleID = parts.dropFirst().joined(separator: ".") }
        }
        let expiration = plist["ExpirationDate"] as? Date ?? Date().addingTimeInterval(365*24*3600)

        // 3. 复制文件到持久目录
        let id = UUID()
        let p12FileName = "\(id.uuidString).p12"
        let profFileName = "\(id.uuidString).mobileprovision"
        let p12Dest = AppState.shared.certsDir.appendingPathComponent(p12FileName)
        let profDest = AppState.shared.certsDir.appendingPathComponent(profFileName)
        try? FileManager.default.removeItem(at: p12Dest)
        try? FileManager.default.removeItem(at: profDest)
        try p12Data.write(to: p12Dest)
        try profData.write(to: profDest)

        // 4. 存密码到 Keychain
        let pwQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "cert_\(id.uuidString)",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        SecItemDelete(pwQuery as CFDictionary)
        SecItemAdd(pwQuery as CFDictionary, nil)

        return SigningCertificate(
            id: id,
            p12Path: "Certificates/\(p12FileName)",
            profilePath: "Certificates/\(profFileName)",
            passwordHint: password.isEmpty ? "(无密码)" : "••••",
            commonName: summary,
            teamID: teamID,
            teamName: displayName,
            validUntil: expiration,
            profileName: profName,
            profileBundleID: bundleID
        )
    }

    static func readPassword(_ id: UUID) -> String {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "cert_\(id.uuidString)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let d = result as? Data,
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
}
