//
//  AppState.swift
//  TianTianSign
//
//  全局单例：持有证书 / 描述文件 / IPA 资料库
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var certificates: [SigningCertificate] = []
    @Published var profiles: [ProvisioningProfile] = []
    @Published var library: [IPAFile] = []
    @Published var recentTasks: [SigningTask] = []

    /// 当前选中的证书 / 描述文件（在签名页用）
    @Published var selectedCertificateID: UUID?
    @Published var selectedProfileID: UUID?

    var selectedCertificate: SigningCertificate? {
        guard let id = selectedCertificateID else { return nil }
        return certificates.first { $0.id == id }
    }
    var selectedProfile: ProvisioningProfile? {
        guard let id = selectedProfileID else { return nil }
        return profiles.first { $0.id == id }
    }

    // MARK: - 沙盒目录
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    lazy var certsDir = documents.appendingPathComponent("Certificates", isDirectory: true)
    lazy var profilesDir = documents.appendingPathComponent("Profiles", isDirectory: true)
    lazy var libraryDir = documents.appendingPathComponent("IPALibrary", isDirectory: true)
    lazy var outputDir = documents.appendingPathComponent("Output", isDirectory: true)
    lazy var tempDir = documents.appendingPathComponent("Temp", isDirectory: true)

    private init() {
        [certsDir, profilesDir, libraryDir, outputDir, tempDir].forEach {
            try? FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true)
        }
        loadMetadata()
    }

    // MARK: - 持久化元信息
    private var metaURL: URL { documents.appendingPathComponent("state.json") }

    func saveMetadata() {
        // 真正的 p12 / mobileprovision 本体留在沙盒，这里只存索引
    }
    func loadMetadata() {}
}
