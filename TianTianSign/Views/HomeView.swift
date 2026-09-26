//
//  HomeView.swift
//  TianTianSign
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var pickedIPA: IPAFile?
    @State private var showingPicker = false
    @State private var newBundleID: String = ""
    @State private var newDisplayName: String = ""
    @State private var taskRunner: SigningViewModel?
    @State private var showingSigningSheet = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("IPA 文件") {
                    if let ipa = pickedIPA {
                        HStack {
                            Image(systemName: "shippingbox").resizable().frame(width: 48, height: 48).foregroundColor(.pink)
                            VStack(alignment: .leading) {
                                Text(ipa.appName).font(.headline)
                                Text("\(ipa.bundleID) · \(ipa.sizeText)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("换一个") { showingPicker = true }
                        }
                    } else {
                        Button { showingPicker = true } label: {
                            Label("从文件 App 导入 IPA", systemImage: "square.and.arrow.down.on.square")
                        }
                    }
                }

                Section("签名证书") {
                    Picker("证书", selection: $appState.selectedCertificateID) {
                        Text("未选择").tag(UUID?.none)
                        ForEach(appState.certificates) { c in
                            Text(c.commonName).tag(UUID?.some(c.id))
                        }
                    }
                    if appState.certificates.isEmpty {
                        Text("还没有证书，先到「证书」页导入 .p12")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Section("描述文件") {
                    Picker("描述文件", selection: $appState.selectedProfileID) {
                        Text("未选择").tag(UUID?.none)
                        ForEach(appState.profiles) { p in
                            Text("\(p.typeBadge) · \(p.bundleID)").tag(UUID?.some(p.id))
                        }
                    }
                }

                Section("可选修改") {
                    TextField("新 Bundle ID（留空不改）", text: $newBundleID)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    TextField("新显示名（留空不改）", text: $newDisplayName)
                }

                Section {
                    Button { startSigning() } label: {
                        HStack {
                            Spacer()
                            Label("开始签名 🍩", systemImage: "checkmark.seal.fill").font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(pickedIPA == nil || appState.selectedCertificate == nil || appState.selectedProfile == nil)
                }
            }
            .navigationTitle("甜甜签")
            .sheet(isPresented: $showingPicker) {
                FilePicker(allowedContentTypes: [.data], allowsMultiple: false) { urls in
                    handleURLs(urls)
                }
            }
            .sheet(isPresented: $showingSigningSheet) {
                if let runner = taskRunner { SigningProgressView(viewModel: runner) }
            }
            .alert("导入提示", isPresented: Binding(
                get: { importError != nil }, set: { if !$0 { importError = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private func handleURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: tmp.path) { try FileManager.default.removeItem(at: tmp) }
            try FileManager.default.copyItem(at: url, to: tmp)
            pickedIPA = try IPAParser.parse(ipazip: tmp)
        } catch {
            importError = "导入失败：\(error.localizedDescription)"
            pickedIPA = nil
        }
    }

    private func startSigning() {
        guard let ipa = pickedIPA,
              let cert = appState.selectedCertificate,
              let prof = appState.selectedProfile else { return }
        var task = SigningTask(id: UUID(), ipa: ipa, certificate: cert, profile: prof)
        task.newBundleID = newBundleID.isEmpty ? nil : newBundleID
        task.newDisplayName = newDisplayName.isEmpty ? nil : newDisplayName
        taskRunner = SigningViewModel(task: task)
        showingSigningSheet = true
        Task { await taskRunner?.start() }
    }
}
