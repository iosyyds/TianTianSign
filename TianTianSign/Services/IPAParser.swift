//
//  IPAParser.swift
//  TianTianSign
//

import Foundation

struct IPAParser {

    static func parse(ipaURL: URL) throws -> IPAFile {
        // 简单解析：从 zip 里找 Payload/xxx.app/Info.plist
        // 用 unzip 命令行（iOS 上有 unzip）
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        // 用 Process 调用 unzip
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        task.arguments = ["-o", ipaURL.path, "-d", tmpDir.path, "Payload/*/Info.plist"]
        try? task.run()
        task.waitUntilExit()

        // 找 Info.plist
        let fm = FileManager.default
        guard let payloadDir = try? fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil),
              let payloadSub = payloadDir.first,
              let appDirs = try? fm.contentsOfDirectory(at: payloadSub, includingPropertiesForKeys: nil),
              let appDir = appDirs.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPAParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "IPA 格式错误：找不到 .app"])
        }

        let infoPlist = appDir.appendingPathComponent("Info.plist")
        var appName = "未知应用"
        var bundleID = "unknown"
        if let data = try? Data(contentsOf: infoPlist),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            appName = plist["CFBundleDisplayName"] as? String
                ?? plist["CFBundleName"] as? String
                ?? "未知应用"
            bundleID = plist["CFBundleIdentifier"] as? String ?? "unknown"
        }

        // 复制 IPA 到持久目录
        let destName = "\(UUID().uuidString).ipa"
        let destURL = AppState.shared.ipaDir.appendingPathComponent(destName)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.copyItem(at: ipaURL, to: destURL)

        let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int64) ?? 0

        try? FileManager.default.removeItem(at: tmpDir)

        return IPAFile(
            id: UUID(),
            fileName: ipaURL.lastPathComponent,
            fileURL: destURL,
            appName: appName,
            bundleID: bundleID,
            sizeBytes: size
        )
    }
}
