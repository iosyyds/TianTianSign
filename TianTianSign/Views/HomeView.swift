//
//  HomeView.swift
//  TianTianSign
//
//  首页：选 IPA → 选证书 → 选描述文件 → 开始签名
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var pickedIPA: IPAFile?
    @State private var showingPicker = false
    @State private var newBundleID: String = ""
    @State private var newDisplayName: String = ""
    @State private var extraOptions: Set<String> = []
    @State private var taskRunner: SigningViewModel?
    @State private var showingSigningSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("IPA 文件") {
                    if let ipa = pickedIPA {
                        HStack {
                            Group {
                                if let icon = ipa.cachedIcon {
                                    Image(uiImage: icon).resizable().frame(width: 48, height: 48).cornerRadius(10)
                                } else {
                                    Image(systemName: "shippingbox").resizable().frame(width: 48, height: 48).foregroundColor(.pink)
                                }
                            }
                            VStack(alignment: .leading) {
                                Text(ipa.appName).font(.headline)
                                Text("\(ipa.bundleID) · \(ipa.sizeText)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("换一个") { showingPicker = true }
                        }
                    } else {
                        Button {
                            showingPicker = true
                        } label: {
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
                    Toggle("移除内嵌 Watch App", isOn: .constant(true))
                    Toggle("注入 / 移除 Dylib（在资料库管理）", isOn: .constant(false))
                }

                Section {
                    Button {
                        startSigning()
                    } label: {
                        HStack {
                            Spacer()
                            Label("开始签名 🍩", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(pickedIPA == nil ||
                              appState.selectedCertificate == nil ||
                              appState.selectedProfile == nil)
                }
            }
            .navigationTitle("甜甜签")
            .fileImporter(isPresented: $showingPicker,
                          allowedContentTypes: [.item],
                          allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showingSigningSheet) {
                if let runner = taskRunner {
                    SigningProgressView(viewModel: runner)
                }
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: tmp.path) {
                try FileManager.default.removeItem(at: tmp)
            }
            try FileManager.default.copyItem(at: url, to: tmp)
            pickedIPA = try IPAParser.parse(ipazip: tmp)
        } catch {
            pickedIPA = nil
        }
    }

    private func startSigning() {
        guard let ipa = pickedIPA,
              let cert = appState.selectedCertificate,
              let prof = appState.selectedProfile else { return }
        var task = SigningTask(id: UUID(),
                               ipa: ipa,
                               certificate: cert,
                               profile: prof)
        task.newBundleID = newBundleID.isEmpty ? nil : newBundleID
        task.newDisplayName = newDisplayName.isEmpty ? nil : newDisplayName
        taskRunner = SigningViewModel(task: task)
        showingSigningSheet = true
        Task { await taskRunner?.start() }
    }
}
