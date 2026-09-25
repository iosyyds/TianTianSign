//
//  SigningEngine.swift
//  TianTianSign
//
//  签名引擎：直接调用静态链接的 zsign C++ 库
//  zsign 命令行等价：
//    zsign -k cert.p12 -p 123456 -m profile.mobileprovision
//          -b new.bundle.id -n newname -o out.ipa in.ipa
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

struct SigningEngine {

    enum EngineError: Error {
        case zsignFailed(Int32, String)
    }

    func run(_ task: inout SigningTask) async throws {
        task.state = .signing
        task.progress = 0.3

        let fm = FileManager.default
        let outName = "TianTian-signed-\(task.ipa.fileName)"
        let outURL = AppState.shared.outputDir.appendingPathComponent(outName)
        try? fm.removeItem(at: outURL)

        // 构造 zsign argv
        var args: [String] = [
            "zsign",
            "-k", task.certificate.p12URL.path,
            "-p", CertificateImporter.readPassword(forCertificateID: task.certificate.id) ?? "",
            "-m", task.profile.fileURL.path,
            "-o", outURL.path,
        ]
        if let b = task.newBundleID, !b.isEmpty {
            args += ["-b", b]
        }
        if let n = task.newDisplayName, !n.isEmpty {
            args += ["-n", n]
        }
        for dylib in task.dylibsToInject {
            args += ["-l", dylib.path]
        }
        for rm in task.dylibsToRemove {
            args += ["-D", rm]
        }
        args.append(task.ipa.fileURL.path)

        task.logLines.append(.init(date: Date(), level: .info,
                                   message: "调用 zsign，参数：\(args.joined(separator: " "))"))

        // 调 C 函数
        let cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
        defer { cArgs.forEach { free($0) } }
        let ret = zsign_ios_run(Int32(args.count), cArgs)

        task.progress = 0.9
        guard ret == 0 else {
            throw EngineError.zsignFailed(ret, "zsign 退出码 \(ret)")
        }

        task.progress = 1.0
        task.outputIPAURL = outURL
    }
}
