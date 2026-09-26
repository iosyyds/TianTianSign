//
//  CertificateImporter.swift
//  TianTianSign
//

import Foundation
import Security

enum CertError: Error, LocalizedError {
    case p12Failed(String)
    var errorDescription: String? {
        switch self {
        case .p12Failed(let m): return m
        }
    }
}

struct CertificateImporter {

    /// 导入 p12：验证密码、复制文件到持久目录、返回证书信息
    static func `import`(p12 srcURL: URL, password: String) throws -> SigningCertificate {
        let data = try Data(contentsOf: srcURL)

        var items: CFArray?
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let dict = array.first,
              let identity = dict[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw CertError.p12Failed("p12 密码错误或文件损坏 (code: \(status))")
        }

        var secCert: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &secCert) == errSecSuccess,
              let cert = secCert else {
            throw CertError.p12Failed("无法读取证书内容")
        }

        let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "未知证书"

        // 提取 teamID
        var teamID = ""
        var displayName = summary
        if let r = summary.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            teamID = String(summary[r]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            displayName = summary.replacingOccurrences(of: String(summary[r]), with: "").trimmingCharacters(in: .whitespaces)
        }

        // 复制到持久目录
        let id = UUID()
        let fileName = "\(id.uuidString).p12"
        let dest = AppState.shared.certsDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: dest)
        try data.write(to: dest)

        // 存密码到 Keychain
        let pwQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "cert_\(id.uuidString)",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        SecItemDelete(pwQuery as CFDictionary)
        SecItemAdd(pwQuery as CFDictionary, nil)

        return SigningCertificate(
            id: id,
            p12Path: "Certificates/\(fileName)",
            passwordHint: password.isEmpty ? "(无密码)" : "••••",
            commonName: summary,
            teamID: teamID,
            teamName: displayName,
            validUntil: Calendar.current.date(byAdding: .year, value: 1, to: Date())!
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
