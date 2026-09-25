//
//  SigningTask.swift
//  TianTianSign
//
//  一次签名任务的参数与进度
//

import Foundation
import SwiftUI

struct SigningTask: Identifiable {
    let id: UUID
    var ipa: IPAFile
    var certificate: SigningCertificate
    var profile: ProvisioningProfile

    // 可选修改
    var newBundleID: String?
    var newDisplayName: String?
    var dylibsToInject: [URL] = []
    var dylibsToRemove: [String] = []
    var shouldReplaceIcon: Bool = false
    var customIconURL: URL? = nil
    var shouldRemoveWatch: Bool = true       // 删掉内嵌 Watch App 减小体积
    var shouldRemovePlugIns: Bool = false    // 删 PlugIns
    var shouldRemoveExtensions: Bool = false

    // 进度
    var state: State = .pending
    var progress: Double = 0
    var logLines: [LogLine] = []
    var outputIPAURL: URL? = nil

    enum State: String {
        case pending
        case unpacking
        case manipulating
        case signing
        case packing
        case done
        case failed
    }

    struct LogLine: Identifiable {
        let id = UUID()
        let date: Date
        let level: Level
        let message: String
        enum Level { case info, warn, error, success }
    }
}
