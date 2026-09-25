//
//  SigningEngine.swift
//  TianTianSign
//
//  签名引擎：把一次 SigningTask 跑完，输出 signed.ipa
//  底层调用静态链接的 zsign (C++) CLI 等价能力
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SigningViewModel: ObservableObject {
    @Published var task: SigningTask
    private var engine = SigningEngine()

    init(task: SigningTask) { self.task = task }

    func start() async {
        task.state = .unpacking
        task.logLines.append(.init(date: Date(), level: .info,
                                   message: "🍩 甜甜签开始工作…"))
        do {
            var localTask = task
            try await engine.run(&localTask)
            task = localTask
            task.state = .done
            task.logLines.append(.init(date: Date(), level: .success,
                                       message: "✅ 签名完成！输出：\(task.outputIPAURL?.lastPathComponent ?? "-")"))
        } catch {
            task.state = .failed
            task.logLines.append(.init(date: Date(), level: .error,
                                       message: "❌ 失败：\(error.localizedDescription)"))
        }
    }
}

/// 真正干活的引擎。设计上对应 zsign 的一条命令：
///   zsign -a in.ipa -k cert.p12 -p 123456 -m profile.mobileprovision
///         -b new.bundle.id -o out.ipa -l dylib1.dylib -r existing.dylib
struct SigningEngine {

    enum EngineError: Error {
        case missingCertificatePassword
        case unpackFailed
        case packFailed
        case signFailed(Int32, String)
    }

    func run(_ task: inout SigningTask) async throws {
        let fm = FileManager.default
        let workDir = AppState.shared.tempDir
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

        // 1. 解包
        task.progress = 0.1
        try unzip(ipa: task.ipa.fileURL, to: workDir)
        let appDir = try locateAppBundle(in: workDir)

        // 2. 清理旧签名 & 替换描述文件
        task.state = .manipulating
        task.progress = 0.3
        try removeOldSignature(at: appDir)
        try replaceProfile(task.profile.fileURL, at: appDir)

        // 3. 改 Bundle ID / 显示名
        if let newID = task.newBundleID, !newID.isEmpty {
            try rewriteBundleID(newID, at: appDir)
        }
        if let name = task.newDisplayName, !name.isEmpty {
            try rewriteDisplayName(name, at: appDir)
        }

        // 4. 注入 / 移除 dylib
        for dylib in task.dylibsToInject {
            try injectDylib(dylib, into: appDir)
        }
        for existing in task.dylibsToRemove {
            try removeDylib(named: existing, from: appDir)
        }

        // 5. 调底层 zsign 重签
        task.state = .signing
        task.progress = 0.6
        let password = CertificateImporter.readPassword(forCertificateID: task.certificate.id) ?? ""
        let ret = zsign_execute(
            appDir.path,
            task.certificate.p12URL.path,
            password,
            task.profile.fileURL.path
        )
        guard ret == 0 else {
            throw EngineError.signFailed(ret, "zsign 退出码 \(ret)")
        }

        // 6. 重新打包
        task.state = .packing
        task.progress = 0.9
        let outName = "TianTian-\(task.ipa.fileName)"
        let outURL = AppState.shared.outputDir.appendingPathComponent(outName)
        try? fm.removeItem(at: outURL)
        try zip(payloadDir: workDir.appendingPathComponent("Payload"), to: outURL)

        task.progress = 1.0
        task.outputIPAURL = outURL
    }

    // MARK: - 私有步骤（这里只给签名，真实实现见 SigningCore/）

    private func unzip(ipa: URL, to dir: URL) throws {
        // 用 NSFileCoordinator / NSFileManager + Data 解压
        // 真实实现：调用 BSD 解压或第三方 ZIP 库（见 SigningCore/unzip.c）
    }
    private func locateAppBundle(in dir: URL) throws -> URL {
        let payload = dir.appendingPathComponent("Payload")
        let apps = (try? FileManager.default.contentsOfDirectory(at: payload,
                    includingPropertiesForKeys: nil))?.filter { $0.pathExtension == "app" } ?? []
        guard let first = apps.first else { throw EngineError.unpackFailed }
        return first
    }
    private func removeOldSignature(at appDir: URL) throws {
        let sig = appDir.appendingPathComponent("_CodeSignature")
        try? FileManager.default.removeItem(at: sig)
    }
    private func replaceProfile(_ profile: URL, at appDir: URL) throws {
        let dest = appDir.appendingPathComponent("embedded.mobileprovision")
        try FileManager.default.copyItem(at: profile, to: dest)
    }
    private func rewriteBundleID(_ id: String, at appDir: URL) throws {}
    private func rewriteDisplayName(_ name: String, at appDir: URL) throws {}
    private func injectDylib(_ url: URL, into appDir: URL) throws {}
    private func removeDylib(named: String, from appDir: URL) throws {}
    private func zip(payloadDir: URL, to ipa: URL) throws {}

    /// 由 SigningCore 暴露的 C 函数：
    /// int zsign_execute(const char* app_dir, const char* p12,
    ///                   const char* pwd, const char* profile);
    private func zsign_execute(_ appDir: String, _ p12: String, _ pwd: String, _ profile: String) -> Int32 {
        // TODO: 链接 SigningCore/libzsign.a 后，这里直接调用
        return 0
    }
}
