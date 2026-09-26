//
//  Certificate.swift
//  TianTianSign
//

import Foundation
import SwiftUI

/// 一份完整的签名证书 = p12 + 对应的 mobileprovision
struct SigningCertificate: Identifiable, Hashable, Codable {
    let id: UUID
    var p12Path: String
    var profilePath: String   // 关联的 mobileprovision
    var passwordHint: String
    var commonName: String
    var teamID: String
    var teamName: String
    var validUntil: Date

    // 描述文件信息（从关联的 mobileprovision 提取）
    var profileName: String
    var profileBundleID: String

    var p12URL: URL {
        AppState.shared.documents.appendingPathComponent(p12Path)
    }
    var profileURL: URL {
        AppState.shared.documents.appendingPathComponent(profilePath)
    }

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0)
    }

    var isExpired: Bool { Date() > validUntil }

    var statusColor: Color {
        if isExpired { return .red }
        if daysLeft <= 7 { return .orange }
        return .green
    }
}
