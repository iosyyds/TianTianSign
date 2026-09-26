//
//  ProfileParser.swift
//  TianTianSign
//
//  解析 .mobileprovision：CMS 签名的 PKCS#7 包裹着 XML plist
//  直接从二进制里提取 plist XML 文本并解析。
//

import Foundation
import Security

struct ProfileParser {

    static func parse(fileURL url: URL) throws -> ProvisioningProfile {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .ascii) else {
            throw NSError(domain: "ProfileParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法读取描述文件"])
        }

        // 提取 <?xml ...>...</plist> 部分
        guard let xmlStartRange = text.range(of: "<?xml"),
              let xmlEndRange = text.range(of: "</plist>") else {
            throw NSError(domain: "ProfileParser", code: -2, userInfo: [NSLocalizedDescriptionKey: "描述文件格式错误：找不到 plist"])
        }
        let xmlString = String(text[xmlStartRange.lowerBound..<xmlEndRange.upperBound])
        guard let plistData = xmlString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw NSError(domain: "ProfileParser", code: -3, userInfo: [NSLocalizedDescriptionKey: "描述文件 plist 解析失败"])
        }

        let uuid = plist["UUID"] as? String ?? UUID().uuidString
        let appIDName = plist["AppIDName"] as? String ?? "Unknown"
        let teamName = (plist["TeamName"] as? String) ?? "Unknown"
        let teamID = ((plist["TeamIdentifier"] as? [String])?.first) ?? ""

        let creationDate = plist["CreationDate"] as? Date ?? Date()
        let expirationDate = plist["ExpirationDate"] as? Date ?? Date().addingTimeInterval(365*24*3600)

        let devices = plist["ProvisionedDevices"] as? [String] ?? []

        var entitlements: [String: AnyCodable] = [:]
        if let ent = plist["Entitlements"] as? [String: Any] {
            for (k, v) in ent {
                entitlements[k] = AnyCodable.from(v)
            }
        }

        let getTaskAllow = (entitlements["get-task-allow"] == .bool(true))

        // 企业 profile 没有 get-task-allow 也不是 development
        let isInHouse = (plist["Name"] as? String)?.contains("In House") ?? false
        var isEnterprise = false
        if let provisionsAllDevices = plist["ProvisionsAllDevices"] as? Bool, provisionsAllDevices {
            isEnterprise = true
        }

        // bundle ID from entitlements
        var bundleID = "*"
        if let appID = entitlements["application-identifier"] {
            if case .string(let s) = appID {
                let parts = s.components(separatedBy: ".")
                if parts.count > 1 {
                    bundleID = parts.dropFirst().joined(separator: ".")
                }
            }
        }

        return ProvisioningProfile(
            id: UUID(),
            fileURL: url,
            uuid: uuid,
            appIDName: appIDName,
            bundleID: bundleID,
            teamName: teamName,
            teamID: teamID,
            creationDate: creationDate,
            expirationDate: expirationDate,
            provisionsDevices: devices,
            isDevelopment: getTaskAllow,
            isEnterprise: isEnterprise || isInHouse,
            entitlements: entitlements
        )
    }
}

extension AnyCodable {
    static func from(_ value: Any) -> AnyCodable {
        if let s = value as? String { return .string(s) }
        if let i = value as? Int { return .int(i) }
        if let b = value as? Bool { return .bool(b) }
        if let arr = value as? [Any] { return .array(arr.map { from($0) }) }
        if let dict = value as? [String: Any] { return .dict(dict.mapValues { from($0) }) }
        return .string("\(value)")
    }
}
