//
//  SigningEngine.swift
//  TianTianSign
//

import Foundation

@MainActor
class SigningViewModel: ObservableObject {
    @Published var task: SigningTask
    private var engine = SigningEngine()

    init(task: SigningTask) { self.task = task }

    func start() async {
        task.state = .unpacking
        task.logLines.append(LogLine(date: Date(), message: "开始签名..."))
        do {
            try await engine.run(task: &task)
            task.state = .done
            task.progress = 1.0
            task.logLines.append(LogLine(date: Date(), message: "签名完成！输出：\(task.outputURL.lastPathComponent)"))
        } catch {
            task.state = .failed
            task.logLines.append(LogLine(date: Date(), message: "失败：\(error.localizedDescription)"))
        }
    }
}

struct SigningEngine {

    func run(task: inout SigningTask) async throws {
        task.state = .signing
        task.progress = 0.2

        let outURL = task.outputURL
        try? FileManager.default.removeItem(at: outURL)

        let password = CertificateImporter.readPassword(task.cert.id)

        var args: [String] = [
            "zsign",
            "-k", task.cert.p12URL.path,
            "-p", password,
            "-m", task.profile.fileURL.path,
            "-o", outURL.path,
        ]
        if let b = task.newBundleID, !b.isEmpty {
            args += ["-b", b]
        }
        if let n = task.newName, !n.isEmpty {
            args += ["-n", n]
        }
        args.append(task.ipaURL.path)

        task.logLines.append(LogLine(date: Date(), message: "运行 zsign..."))

        var cArgs: [UnsafePointer<CChar>?] = args.map { UnsafePointer(strdup($0)) }
        defer { cArgs.forEach { free(UnsafeMutablePointer(mutating: $0)) } }

        let ret = zsign_ios_run(Int32(args.count), &cArgs)
        task.progress = 0.9

        guard ret == 0 else {
            throw NSError(domain: "zsign", code: Int(ret), userInfo: [NSLocalizedDescriptionKey: "zsign 退出码 \(ret)"])
        }
    }
}
