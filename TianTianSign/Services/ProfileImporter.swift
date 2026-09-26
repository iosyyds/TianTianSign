//
//  ProfileImporter.swift
//  TianTianSign
//

import Foundation

struct ProfileImporter {

    /// 解析 mobileprovision 并复制到持久目录
    static func `import`(srcURL: URL) throws -> ProvisioningProfile {
        let data = try Data(contentsOf: srcURL)
        guard let text = String(data: data, encoding: .ascii) else {
            throw NSError(domain: "ProfileImporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法读取描述文件"])
        }
        guard let xmlStart = text.range(of: "<?xml"),
              let xmlEnd = text.range(of: "</plist>") else {
            throw NSError(domain: "ProfileImporter", code: -2, userInfo: [NSLocalizedDescriptionKey: "描述文件格式错误"])
        }
        let xml = String(text[xmlStart.lowerBound..<xmlEnd.upperBound])
        guard let plistData = xml.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw NSError(domain: "ProfileImporter", code: -3, userInfo: [NSLocalizedDescriptionKey: "描述文件解析失败"])
        }

        let uuid = plist["UUID"] as? String ?? UUID().uuidString
        let name = plist["Name"] as? String ?? "描述文件"
        let teamName = plist["TeamName"] as? String ?? ""
        let teamID = (plist["TeamIdentifier"] as? [String])?.first ?? ""
        let expiration = plist["ExpirationDate"] as? Date ?? Date().addingTimeInterval(365*24*3600)

        var bundleID = "*"
        if let ent = plist["Entitlements"] as? [String: Any],
           let appID = ent["application-identifier"] as? String {
            let parts = appID.components(separatedBy: ".")
            if parts.count > 1 { bundleID = parts.dropFirst().joined(separator: ".") }
        }

        let getTaskAllow = (plist["Entitlements"] as? [String: Any])?["get-task-allow"] as? Bool ?? false
        let provisionsAll = plist["ProvisionsAllDevices"] as? Bool ?? false

        // 复制到持久目录
        let id = UUID()
        let fileName = "\(id.uuidString).mobileprovision"
        let dest = AppState.shared.profilesDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: dest)
        try data.write(to: dest)

        return ProvisioningProfile(
            id: id,
            filePath: "Profiles/\(fileName)",
            uuid: uuid,
            name: name,
            bundleID: bundleID,
            teamName: teamName,
            teamID: teamID,
            expirationDate: expiration,
            isDevelopment: getTaskAllow,
            isEnterprise: provisionsAll
        )
    }
}
