//
//  SigningTask.swift
//  TianTianSign
//

import Foundation

struct SigningTask {
    let id: UUID
    let ipaURL: URL
    let ipaName: String
    let cert: SigningCertificate
    let newBundleID: String?
    let newName: String?

    var outputURL: URL {
        AppState.shared.outputDir.appendingPathComponent("signed-\(ipaName)")
    }

    var state: SignState = .idle
    var progress: Double = 0
    var logLines: [LogLine] = []

    enum SignState {
        case idle, unpacking, signing, done, failed
    }
}

struct LogLine: Identifiable {
    let id = UUID()
    let date: Date
    let message: String
}
