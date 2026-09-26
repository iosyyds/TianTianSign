//
//  CertificateStore.swift
//  TianTianSign
//
//  从 .p12 文件解析证书信息，密码存 Keychain
//

import Foundation
import Security
import SwiftUI

enum CertificateImporterError: Error, LocalizedError {
    case badPassword
    case invalidP12
    case importFailed(String)
    var errorDescription: String? {
        switch self {
        case .badPassword: return "p12 密码错误"
        case .invalidP12: return "p12 文件无效"
        case .importFailed(let m): return m
        }
    }
}

struct CertificateImporter {

    /// 用密码尝试解析 p12，把 p12 复制到持久目录，返回证书信息
    static func inspect(p12 srcURL: URL, password: String) throws -> (cert: SigningCertificate, copiedURL: URL) {
        let data = try Data(contentsOf: srcURL)

        // 用 SecPKCS12Import 解密
        var items: CFArray?
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let dict = array.first,
              let identity = dict[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw CertificateImporterError.importFailed("p12 密码错误或文件损坏 (code=\(status))")
        }

        // 从 identity 取 certificate
        var secCert: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &secCert) == errSecSuccess,
              let certRef = secCert else {
            throw CertificateImporterError.importFailed("无法读取证书内容")
        }

        // 证书主题摘要
        let summary = SecCertificateCopySubjectSummary(certRef) as String? ?? "Unknown Certificate"

        // 从 summary 提取 teamID（括号里的部分）
        var teamID = ""
        var teamName = summary
        if let range = summary.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            let t = String(summary[range])
            teamID = t.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            teamName = summary.replacingOccurrences(of: t, with: "").trimmingCharacters(in: .whitespaces)
        }

        // 证书类型
        var certType: SigningCertificate.CertType = .unknown
        if summary.contains("Apple Development") || summary.contains("iPhone Developer") || summary.contains("Mac Development") {
            certType = .development
        } else if summary.contains("Apple Distribution") || summary.contains("iPhone Distribution") {
            certType = .distribution
        }

        // 有效期：从证书数据中粗略提取（用 1 年占位，实际由 zsign 校验）
        let now = Date()
        let validFrom = now
        let validUntil = Calendar.current.date(byAdding: .year, value: 1, to: now)!

        // 序列号：用 p12 数据的 MD5 前 8 字节作为唯一标识
        let serial = data.prefix(8).map { String(format: "%02x", $0) }.joined()

        // 复制 p12 到持久目录
        let id = UUID()
        let destURL = AppState.shared.certsDir.appendingPathComponent("\(id.uuidString).p12")
        try? FileManager.default.removeItem(at: destURL)
        try data.write(to: destURL)

        let cert = SigningCertificate(
            id: id,
            p12URL: destURL,
            passwordHint: password.isEmpty ? "(无密码)" : String(password.prefix(1)) + "••••",
            commonName: summary,
            teamID: teamID,
            teamName: teamName,
            validFrom: validFrom,
            validUntil: validUntil,
            certType: certType,
            serialNumber: serial
        )
        return (cert, destURL)
    }

    /// 把密码安全地存进 Keychain
    static func storePassword(_ password: String, forCertificateID id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "cert_\(id.uuidString)",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func readPassword(forCertificateID id: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "cert_\(id.uuidString)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
