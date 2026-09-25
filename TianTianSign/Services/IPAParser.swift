//
//  IPAParser.swift
//  TianTianSign
//
//  解析一个 .ipa：列出 Payload、读 Info.plist、抽图标
//

import Foundation
import UIKit

struct IPAParser {

    static func parse(ipazip url: URL) throws -> IPAFile {
        // 1. 解压到临时目录
        // 2. 找 Payload/*.app
        // 3. 读 Info.plist: CFBundleDisplayName / CFBundleIdentifier /
        //    CFBundleShortVersionString / CFBundleVersion
        // 4. 用 otool 思路读 Mach-O 头拿到架构（arm64 / arm64e）
        // 5. 加载 AppIcon60x60@2x 作为缩略图
        //
        // 这里返回占位，保证 App 能跑通 UI；真实解析见 SigningCore/
        let fm = FileManager.default
        let attrs = try? fm.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? Int64) ?? 0
        return IPAFile(
            id: UUID(),
            fileURL: url,
            fileName: url.lastPathComponent,
            appName: url.deletingPathExtension().lastPathComponent,
            bundleID: "com.example.app",
            version: "1.0.0",
            buildVersion: "1",
            architectures: ["arm64"],
            sizeBytes: size,
            importedAt: Date(),
            cachedIcon: nil
        )
    }
}
