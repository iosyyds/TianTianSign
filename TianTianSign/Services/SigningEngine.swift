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
            let output = try await engine.run(
                ipaURL: task.ipaURL,
                p12URL: task.cert.p12URL,
                password: CertificateImporter.readPassword(task.cert.id),
                profileURL: task.cert.profileURL,
                outputURL: task.outputURL,
                newBundleID: task.newBundleID,
                newName: task.newName
            )
            task.state = .done
            task.progress = 1.0
            task.logLines.append(LogLine(date: Date(), message: "签名完成！输出：\(output.lastPathComponent)"))
        } catch {
            task.state = .failed
            task.logLines.append(LogLine(date: Date(), message: "失败：\(error.localizedDescription)"))
        }
    }
}

struct SigningEngine {

    func run(
        ipaURL: URL,
        p12URL: URL,
        password: String,
        profileURL: URL,
        outputURL: URL,
        newBundleID: String?,
        newName: String?
    ) async throws -> URL {
        try? FileManager.default.removeItem(at: outputURL)

        var args: [String] = [
            "zsign",
            "-k", p12URL.path,
            "-p", password,
            "-m", profileURL.path,
            "-o", outputURL.path,
        ]
        if let b = newBundleID, !b.isEmpty {
            args += ["-b", b]
        }
        if let n = newName, !n.isEmpty {
            args += ["-n", n]
        }
        args.append(ipaURL.path)

        return try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var cArgs: [UnsafePointer<CChar>?] = args.map { UnsafePointer(strdup($0)) }
                defer { cArgs.forEach { free(UnsafeMutablePointer(mutating: $0)) } }
                let ret = zsign_ios_run(Int32(args.count), &cArgs)
                if ret == 0 {
                    cont.resume(returning: outputURL)
                } else {
                    cont.resume(throwing: NSError(domain: "zsign", code: Int(ret),
                        userInfo: [NSLocalizedDescriptionKey: "zsign 退出码 \(ret)"]))
                }
            }
        }
    }
}
