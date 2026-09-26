//
//  Certificate.swift
//  TianTianSign
//

import Foundation
import SwiftUI

struct SigningCertificate: Identifiable, Hashable, Codable {
    let id: UUID
    var p12Path: String   // 相对 Documents 的路径
    var passwordHint: String
    var commonName: String
    var teamID: String
    var teamName: String
    var validUntil: Date

    var p12URL: URL {
        AppState.shared.documents.appendingPathComponent(p12Path)
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
