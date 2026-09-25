//
//  ProfileParser.swift
//  TianTianSign
//
//  解析 .mobileprovision：它其实是一个 CMS 签名的 PKCS#7
//  包裹着一段 XML plist。iOS 上用 Security.framework 解密。
//

import Foundation
import Security

struct ProfileParser {

    static func parse(fileURL url: URL) throws -> ProvisioningProfile {
        let data = try Data(contentsOf: url)

        // SecCMS 解码（iOS 15+ 有 CMSDecoder 私有 API；
        // 开源项目里常见做法是直接调 OpenSSL d2i_PKCS7_bio）
        // 解析后的 plist 里有：
        //   UUID, AppIDName, TeamName, TeamIdentifier,
        //   CreationDate, ExpirationDate, ProvisionedDevices,
        //   Entitlements, Entitlements[get-task-allow]
        //
        // 占位实现：
        return ProvisioningProfile(
            id: UUID(),
            fileURL: url,
            uuid: UUID().uuidString,
            appIDName: "iOS Team Provisioning Profile: *",
            bundleID: "*",
            teamName: "Example Team",
            teamID: "TEAMID",
            creationDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            provisionsDevices: [],
            isDevelopment: true,
            isEnterprise: false,
            entitlements: [:]
        )
    }
}
