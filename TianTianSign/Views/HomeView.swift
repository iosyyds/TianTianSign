//
//  LibraryView.swift
//  TianTianSign
//  Feather-style library.
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

                    Section("签名") {
                        Picker("证书", selection: $appState.selectedCertificateID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.certificates) { c in
                                Text(c.commonName).tag(UUID?.some(c.id))
                            }
                        }
                        if appState.certificates.isEmpty {
                            Text("请到「证书」标签页导入证书")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Section("修改") {
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
                                Label("开始签名", systemImage: "signature")
                                Spacer()
                            }
                        }
                        .disabled(pickedIPA == nil || appState.selectedCertificate == nil || appState.selectedProfile == nil)
                    }
                } else {
                    ContentUnavailableView {
                        Label("没有应用", systemImage: "questionmark.app.dashed")
                    } description: {
                        Text("导入你的 IPA 文件开始签名")
                    } actions: {
                        Button {
                            showingImport = true
                        } label: {
                            Label("导入 IPA", systemImage: "square.and.arrow.down.on.square")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
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
