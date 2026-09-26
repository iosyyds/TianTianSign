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
            throw CertificateImporterError.importFailed("p12 密码错误或文件损坏 (status=\(status))")
        }

        // 从 identity 取 certificate
        var certRef: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &certRef) == errSecSuccess,
              let cert = certRef else {
            throw CertificateImporterError.importFailed("无法读取证书内容")
        }

        // 提取 subject 信息
        let subjectDict = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"

        // 用 SecCertificateCopyValues 拿详细字段
        var commonName = subjectDict
        var teamID = ""
        var teamName = ""
        var serialNumber = ""

        if let values = SecCertificateCopyValues(cert, nil, nil) as? [[String: Any]] {
            for field in values {
                let label = field[kSecOIDAttributeName as String] as? String ?? ""
                if label == "Z" { break } // 结束
            }
        }

        // 更可靠：直接解析 subject summary 里的内容
        // CN = "Apple Development: xxx (TEAMID)"
        // 尝试提取括号里的 teamID
        if let range = commonName.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            teamID = String(commonName[range]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        }

        // 有效期
        var validFrom = Date()
        var validUntil = Date().addingTimeInterval(365*24*3600)
        if let notBefore = SecCertificateCopyNormalizedDate(cert, key: kSecOIDX509V1ValidityNotBefore) {
            validFrom = notBefore
        }
        if let notAfter = SecCertificateCopyNormalizedDate(cert, key: kSecOIDX509V1ValidityNotAfter) {
            validUntil = notAfter
        }

        // 序列号
        if let snData = SecCertificateCopySerialNumberData(cert, nil) {
            serialNumber = snData.map { String(format: "%02x", $0) }.joined()
        }

        // 证书类型判断
        var certType: SigningCertificate.CertType = .unknown
        if commonName.contains("Apple Development") || commonName.contains("Mac Development") {
            certType = .development
        } else if commonName.contains("Apple Distribution") || commonName.contains("iPhone Distribution") {
            certType = .distribution
        } else if commonName.contains("iPhone Developer") || commonName.contains("Mac Developer") {
            certType = .development
        }

        // teamName：从 commonName 里去掉 teamID 括号部分
        teamName = commonName
            .replacingOccurrences(of: #"\s*\([^)]+\)"#, with: "", options: .regularExpression)

        // 复制 p12 到持久目录
        let id = UUID()
        let destURL = AppState.shared.certsDir.appendingPathComponent("\(id.uuidString).p12")
        try? FileManager.default.removeItem(at: destURL)
        try data.write(to: destURL)

        let cert = SigningCertificate(
            id: id,
            p12URL: destURL,
            passwordHint: String(password.prefix(1)) + "••••",
            commonName: commonName,
            teamID: teamID,
            teamName: teamName,
            validFrom: validFrom,
            validUntil: validUntil,
            certType: certType,
            serialNumber: serialNumber
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

// MARK: - SecCertificate date extraction
private extension SecCertificate {
    static func _dateValue(for key: CFString, in values: [[String: Any]]) -> Date? {
        for field in values {
            if let oid = field[kSecOIDAttributeName as String] as? String, oid == key as String,
               let valueDict = field[kSecValueData as String] as? [String: Any],
               let date = valueDict["value"] as? Date {
                return date
            }
        }
        return nil
    }
}

private func SecCertificateCopyNormalizedDate(_ cert: SecCertificate, key: CFString) -> Date? {
    var error: Unmanaged<CFError>?
    guard let values = SecCertificateCopyValues(cert, nil, &error) as? [[String: Any]] else {
        return nil
    }
    for field in values {
        if let oid = field[kSecOIDAttributeName as String] as? String, oid == key as String,
           let valueDict = field[kSecValueData as String] as? [String: Any] {
            if let date = valueDict["value"] as? Date {
                return date
            }
        }
    }
    return nil
}
