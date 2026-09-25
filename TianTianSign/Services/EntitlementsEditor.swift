//
//  EntitlementsEditor.swift
//  TianTianSign
//
//  可视化编辑签名时要写进二进制的 entitlements.plist
//

import Foundation

struct EntitlementsEditor {
    /// 从描述文件里读出基础 entitlements，再叠加用户的勾选
    static func merged(base: [String: AnyCodable],
                       overrides: Set<String>) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in base {
            switch v {
            case .string(let s): out[k] = s
            case .int(let i): out[k] = i
            case .bool(let b): out[k] = b
            case .array(let a): out[k] = a.map { $0 }
            case .dict(let d): out[k] = d
            }
        }
        // 用户显式开关
        out["get-task-allow"] = overrides.contains("get-task-allow")
        if overrides.contains("aps-production") {
            out["aps-environment"] = "production"
        }
        return out
    }
}
