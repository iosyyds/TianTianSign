//
//  LibraryView.swift
//  TianTianSign
//  资料库页面：导入 IPA → 选证书/描述文件 → 签名
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImport = false
    @State private var pickedIPA: IPAFile?
    @State private var newBundleID = ""
    @State private var newDisplayName = ""
    @State private var taskRunner: SigningViewModel?
    @State private var showingSigning = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Form {
                if let ipa = pickedIPA {
                    Section("已选应用") {
                        HStack(spacing: 12) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.pink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ipa.appName).font(.headline)
                                Text("\(ipa.bundleID) · \(ipa.sizeText)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Section("签名证书") {
                        Picker("证书", selection: $appState.selectedCertificateID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.certificates) { c in
                                Text(c.commonName).tag(UUID?.some(c.id))
                            }
                        }
                        .onChange(of: appState.selectedCertificateID) { _, _ in
                            appState.save()
                        }
                        Picker("描述文件", selection: $appState.selectedProfileID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.profiles) { p in
                                Text("\(p.appIDName) (\(p.typeBadge))").tag(UUID?.some(p.id))
                            }
                        }
                        .onChange(of: appState.selectedProfileID) { _, _ in
                            appState.save()
                        }

                        if appState.certificates.isEmpty {
                            Text("请先到「证书」页导入 p12 证书")
                                .font(.caption).foregroundColor(.orange)
                        } else if appState.selectedCertificate == nil {
                            Text("请选择一个证书")
                                .font(.caption).foregroundColor(.orange)
                        }
                        if appState.profiles.isEmpty {
                            Text("请先到「证书」页导入描述文件")
                                .font(.caption).foregroundColor(.orange)
                        } else if appState.selectedProfile == nil {
                            Text("请选择一个描述文件")
                                .font(.caption).foregroundColor(.orange)
                        }
                    }

                    Section("修改（可选）") {
                        TextField("新 Bundle ID（留空不改）", text: $newBundleID)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        TextField("新显示名（留空不改）", text: $newDisplayName)
                    }

                    Section {
                        Button {
                            startSigning()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "signature")
                                Text("开始签名")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(appState.selectedCertificate == nil || appState.selectedProfile == nil)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("没有应用")
                            .font(.headline)
                        Text("导入 IPA 文件开始签名")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingImport = true
                        } label: {
                            Text("导入 IPA")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.pink)
                                .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("资料库")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImport) {
                FilePicker(allowedContentTypes: [.ipa], allowsMultipleSelection: false) { urls in
                    handleURLs(urls)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSigning) {
                if let runner = taskRunner { SigningProgressView(viewModel: runner) }
            }
            .alert("导入失败", isPresented: Binding(
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
        do {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: tmp.path) {
                try FileManager.default.removeItem(at: tmp)
            }
            try FileManager.default.copyItem(at: url, to: tmp)
            pickedIPA = try IPAParser.parse(ipazip: tmp)
        } catch {
            importError = error.localizedDescription
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
        showingSigning = true
        Task { await taskRunner?.start() }
    }
}
