//
//  ProvisioningProfile.swift
//  TianTianSign
//
//  描述文件 (.mobileprovision) 模型
//

import Foundation
import SwiftUI

struct ProvisioningProfile: Identifiable, Hashable, Codable {
    let id: UUID
    /// 本地文件 URL
    var fileURL: URL
    /// Profile UUID
    var uuid: String
    /// AppID 标识，例如 "group.com.xxx.*"
    var appIDName: String
    var bundleID: String
    /// Team
    var teamName: String
    var teamID: String
    /// 有效期
    var creationDate: Date
    var expirationDate: Date
    /// 包含的 UDID 列表（开发 / Ad Hoc profile 才有）
    var provisionsDevices: [String]
    /// 是否为调试 profile（允许 get-task-allow）
    var isDevelopment: Bool
    /// 是否为企业 In-House
    var isEnterprise: Bool
    /// 内嵌的 entitlements
    var entitlements: [String: AnyCodable]

    var isExpired: Bool { Date() > expirationDate }
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
    }

    var statusColor: Color {
        if isExpired { return .red }
        if daysRemaining <= 7 { return .orange }
        return .green
    }

    var typeBadge: String {
        if isEnterprise { return "企业" }
        if isDevelopment { return "开发" }
        return "发布"
    }
}

/// 让任意 JSON 值都能 Codable
enum AnyCodable: Codable, Hashable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([AnyCodable])
    case dict([String: AnyCodable])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Int.self) { self = .int(v) }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode([AnyCodable].self) { self = .array(v) }
        else if let v = try? c.decode([String: AnyCodable].self) { self = .dict(v) }
        else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported type")
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .dict(let v): try c.encode(v)
        }
    }
}
