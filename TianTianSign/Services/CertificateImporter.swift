//
//  CertificateImporter.swift
//  TianTianSign
//

import Foundation
import UIKit

struct CertificateImporter {

    enum ImportError: Error, LocalizedError {
        case invalidP12
        case invalidProfile
        case copyFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidP12: return "证书文件格式错误（请选择 .p12 文件）"
            case .invalidProfile: return "描述文件格式错误（请选择 .mobileprovision 文件）"
            case .copyFailed(let msg): return "文件保存失败：\(msg)"
            }
        }
    }

    /// Import p12 + mobileprovision pair. Matches the API used by CertificatesView.
    static func `import`(p12: URL, profile: URL, password: String) throws -> SigningCertificate {
        let p12Ext = p12.pathExtension.lowercased()
        guard p12Ext == "p12" else { throw ImportError.invalidP12 }

        let profileExt = profile.pathExtension.lowercased()
        guard profileExt == "mobileprovision" || profileExt == "provision" else {
            throw ImportError.invalidProfile
        }

        let id = UUID()
        let docs = AppState.shared.documents
        let certRelDir = "certs/\(id.uuidString)"
        let fullDir = docs.appendingPathComponent(certRelDir, isDirectory: true)
        try FileManager.default.createDirectory(at: fullDir, withIntermediateDirectories: true)

        let p12Needs = p12.startAccessingSecurityScopedResource()
        defer { if p12Needs { p12.stopAccessingSecurityScopedResource() } }
        let profNeeds = profile.startAccessingSecurityScopedResource()
        defer { if profNeeds { profile.stopAccessingSecurityScopedResource() } }

        let p12Rel = "\(certRelDir)/cert.p12"
        let p12Dest = docs.appendingPathComponent(p12Rel)
        if FileManager.default.fileExists(atPath: p12Dest.path) {
            try FileManager.default.removeItem(at: p12Dest)
        }
        do {
            try FileManager.default.copyItem(at: p12, to: p12Dest)
        } catch {
            throw ImportError.copyFailed("p12: \(error.localizedDescription)")
        }

        let profRel = "\(certRelDir)/embedded.mobileprovision"
        let profDest = docs.appendingPathComponent(profRel)
        if FileManager.default.fileExists(atPath: profDest.path) {
            try FileManager.default.removeItem(at: profDest)
        }
        do {
            try FileManager.default.copyItem(at: profile, to: profDest)
        } catch {
            throw ImportError.copyFailed("provision: \(error.localizedDescription)")
        }

        // mobileprovision is CMS signed data; the plist is embedded between <plist ...> and </plist>.
        // Do NOT PropertyListSerialization the whole file.
        var profileName = "描述文件"
        var bundleID = "*"
        var teamName = ""
        var teamID = ""
        var validUntil = Date().addingTimeInterval(365 * 24 * 3600)

        if let data = try? Data(contentsOf: profDest),
           let str = String(data: data, encoding: .ascii),
           let bStart = str.range(of: "<plist"),
           let bEnd = str.range(of: "</plist>") {
            let plistStr = String(str[bStart.lowerBound..<bEnd.upperBound])
            if let plData = plistStr.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plData, options: [], format: nil) as? [String: Any] {
                if let name = plist["Name"] as? String { profileName = name }
                if let ent = plist["Entitlements"] as? [String: Any],
                   let bid = ent["application-identifier"] as? String {
                    bundleID = bid.components(separatedBy: ".").dropFirst().joined(separator: ".")
                }
                if let tn = plist["TeamName"] as? String { teamName = tn }
                if let teams = plist["TeamIdentifier"] as? [String] { teamID = teams.first ?? "" }
                if let exp = plist["ExpirationDate"] as? Date { validUntil = exp }
            }
        }

        // Save password
        savePassword(password, for: id)

        return SigningCertificate(
            id: id,
            p12Path: p12Rel,
            profilePath: profRel,
            passwordHint: password.isEmpty ? "无密码" : "已保存",
            commonName: profileName,
            teamID: teamID,
            teamName: teamName,
            validUntil: validUntil,
            profileName: profileName,
            profileBundleID: bundleID
        )
    }

    static func readPassword(_ certID: UUID) -> String {
        return loadPassword(for: certID) ?? ""
    }

    // MARK: - Password storage
    private static let pwdKeyPrefix = "cert_pwd_"

    private static func savePassword(_ pwd: String, for id: UUID) {
        UserDefaults.standard.set(pwd, forKey: pwdKeyPrefix + id.uuidString)
    }

    private static func loadPassword(for id: UUID) -> String? {
        return UserDefaults.standard.string(forKey: pwdKeyPrefix + id.uuidString)
    }
}
