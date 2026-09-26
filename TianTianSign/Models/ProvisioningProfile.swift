//
//  ProvisioningProfile.swift
//  TianTianSign
//

import Foundation
import SwiftUI

struct ProvisioningProfile: Identifiable, Hashable, Codable {
    let id: UUID
    var filePath: String
    var uuid: String
    var name: String
    var bundleID: String
    var teamName: String
    var teamID: String
    var expirationDate: Date
    var isDevelopment: Bool
    var isEnterprise: Bool

    var fileURL: URL {
        AppState.shared.documents.appendingPathComponent(filePath)
    }

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
    }

    var isExpired: Bool { Date() > expirationDate }

    var statusColor: Color {
        if isExpired { return .red }
        if daysLeft <= 7 { return .orange }
        return .green
    }

    var typeLabel: String {
        if isEnterprise { return "企业" }
        if isDevelopment { return "开发" }
        return "发布"
    }
}
