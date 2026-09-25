//
//  IPAFile.swift
//  TianTianSign
//
//  导入到资料库的 IPA 文件
//

import Foundation
import SwiftUI

struct IPAFile: Identifiable {
    let id: UUID
    /// 本地文件 URL（Documents/IPALibrary/）
    var fileURL: URL
    /// 原始文件名
    var fileName: String
    /// App 显示名（从 Info.plist 读 CFBundleDisplayName）
    var appName: String
    /// Bundle ID
    var bundleID: String
    /// 版本号
    var version: String
    /// Build
    var buildVersion: String
    /// 二进制架构：arm64 / arm64e
    var architectures: [String]
    /// 文件大小（字节）
    var sizeBytes: Int64
    /// 导入时间
    var importedAt: Date
    /// 缓存的图标（解码自 Payload/XXX.app/AppIcon60x60@2x.png）
    var cachedIcon: UIImage?

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}
