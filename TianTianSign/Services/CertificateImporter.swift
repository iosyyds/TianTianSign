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

    static let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    /// Import a pair of p12 + mobileprovision into Documents/certs/<uuid>/
    /// - Returns: SigningCertificate with p12Path and profilePath
    static func importPair(p12URL: URL, profileURL: URL) throws -> SigningCertificate {
        // Validate by extension only — mobileprovision is CMS signed data, NOT a plist.
        // Do NOT use PropertyListSerialization to check it; that rejects valid profiles.
        let p12Ext = p12URL.pathExtension.lowercased()
        guard p12Ext == "p12" || p12Ext == "p12b" else {
            throw ImportError.invalidP12
        }

        let profileExt = profileURL.pathExtension.lowercased()
        guard profileExt == "mobileprovision" || profileExt == "provision" else {
            throw ImportError.invalidProfile
        }

        // Create unique cert directory
        let certID = UUID().uuidString
        let certDir = documentsDir.appendingPathComponent("certs/\(certID)", isDirectory: true)
        try FileManager.default.createDirectory(at: certDir, withIntermediateDirectories: true)

        // Start accessing security-scoped resource
        let p12NeedsStop = p12URL.startAccessingSecurityScopedResource()
        defer { if p12NeedsStop { p12URL.stopAccessingSecurityScopedResource() } }

        let profileNeedsStop = profileURL.startAccessingSecurityScopedResource()
        defer { if profileNeedsStop { profileURL.stopAccessingSecurityScopedResource() } }

        // Copy p12
        let p12Dest = certDir.appendingPathComponent("cert.p12")
        if FileManager.default.fileExists(atPath: p12Dest.path) {
            try FileManager.default.removeItem(at: p12Dest)
        }
        do {
            try FileManager.default.copyItem(at: p12URL, to: p12Dest)
        } catch {
            throw ImportError.copyFailed("p12: \(error.localizedDescription)")
        }

        // Copy mobileprovision
        let profileDest = certDir.appendingPathComponent("embedded.mobileprovision")
        if FileManager.default.fileExists(atPath: profileDest.path) {
            try FileManager.default.removeItem(at: profileDest)
        }
        do {
            try FileManager.default.copyItem(at: profileURL, to: profileDest)
        } catch {
            throw ImportError.copyFailed("mobileprovision: \(error.localizedDescription)")
        }

        // Read profile name from embedded plist inside CMS data (best-effort display)
        var displayName = "证书 \(Date().formatted(date: .abbreviated, time: .omitted))"
        if let data = try? Data(contentsOf: profileDest),
           let str = String(data: data, encoding: .ascii),
           let bStart = str.range(of: "<plist"),
           let bEnd = str.range(of: "</plist>") {
            let plistStr = String(str[bStart.lowerBound..<bEnd.upperBound])
            if let plData = plistStr.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plData, options: [], format: nil) as? [String: Any],
               let name = plist["Name"] as? String {
                displayName = name
            }
        }

        return SigningCertificate(
            id: certID,
            displayName: displayName,
            p12Path: p12Dest.path,
            profilePath: profileDest.path,
            importedAt: Date()
        )
    }

    /// Delete a certificate pair from disk
    static func deleteCertificate(_ cert: SigningCertificate) {
        let dir = URL(fileURLWithPath: cert.p12Path).deletingLastPathComponent()
        try? FileManager.default.removeItem(at: dir)
    }
}
