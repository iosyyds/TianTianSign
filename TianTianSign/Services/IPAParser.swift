//
//  IPAParser.swift
//  TianTianSign
//

import Foundation

struct IPAParser {

    static func parse(ipaURL: URL) throws -> IPAFile {
        // 复制 IPA 到持久目录
        let destName = "\(UUID().uuidString).ipa"
        let destURL = AppState.shared.ipaDir.appendingPathComponent(destName)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.copyItem(at: ipaURL, to: destURL)

        let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int64) ?? 0

        return IPAFile(
            id: UUID(),
            fileName: ipaURL.lastPathComponent,
            fileURL: destURL,
            appName: ipaURL.deletingPathExtension().lastPathComponent,
            bundleID: "",
            sizeBytes: size
        )
    }
}
