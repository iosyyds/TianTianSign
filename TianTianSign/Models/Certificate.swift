//
//  Certificate.swift
//  TianTianSign
//
//  一份待使用的 iOS 签名证书 (.p12)
//

import Foundation
import SwiftUI

struct SigningCertificate: Identifiable, Hashable {
    /// 内部 UUID
    let id: UUID
    /// p12 文件在 App 沙盒中的持久化 URL
    var p12URL: URL
    /// 解密 p12 的密码（存在 Keychain，不写入此结构体持久层）
    var passwordHint: String
    /// 证书展示名（从 CN 字段读出），例如 "Apple Development: XXX (TEAMID)"
    var commonName: String
    /// 团队 ID，例如 "A1B2C3D4E5"
    var teamID: String
    /// 团队名字
    var teamName: String
    /// 证书有效期
    var validFrom: Date
    var validUntil: Date
    /// 证书类型：开发 / 发布 / 企业
    var certType: CertType
    /// 证书序列号（hex），用于去重
    var serialNumber: String

    enum CertType: String, Codable {
        case development   // Apple Development
        case distribution  // Apple Distribution (App Store / Ad Hoc)
        case enterprise    // In-House (企业)
        case unknown
    }

    /// 是否仍然有效
    var isExpired: Bool { Date() > validUntil }

    /// 剩余天数
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0)
    }

    /// 状态颜色
    var statusColor: Color {
        if isExpired { return .red }
        if daysRemaining <= 7 { return .orange }
        return .green
    }
}

// MARK: - 持久化（仅保存元信息，p12 本体留在 Documents/Certificates/）

extension SigningCertificate: Codable {}
