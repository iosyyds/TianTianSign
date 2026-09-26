//
//  LibraryView.swift
//  TianTianSign
//  Feather-style library with empty state and import button.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPicker = false
    @State private var pickedIPA: IPAFile?
    @State private var newBundleID: String = ""
    @State private var newDisplayName: String = ""
    @State private var taskRunner: SigningViewModel?
    @State private var showingSigningSheet = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Form {
                if let ipa = pickedIPA {
                    Section("已选 IPA") {
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.pink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ipa.appName).font(.headline)
                                Text("\(ipa.bundleID) · \(ipa.sizeText)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("更换") { showingPicker = true }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("签名证书") {
                        Picker("证书", selection: $appState.selectedCertificateID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.certificates) { c in
                                Text(c.commonName).tag(UUID?.some(c.id))
                            }
                        }
                        if appState.certificates.isEmpty {
                            Text("先到「证书」页导入 .p12 和描述文件")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Section("可选修改") {
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
                                Label("开始签名", systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .disabled(pickedIPA == nil || appState.selectedCertificate == nil || appState.selectedProfile == nil)
                    }
                } else {
                    ContentUnavailableView {
                        Label("没有应用", systemImage: "questionmark.app.dashed")
                    } description: {
                        Text("点击下方按钮导入你的 IPA 文件开始签名")
                    } actions: {
                        Button {
                            showingPicker = true
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
                        showingPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                FilePicker(allowedContentTypes: [.ipa], allowsMultiple: false) { urls in
                    handleURLs(urls)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSigningSheet) {
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
        showingSigningSheet = true
        Task { await taskRunner?.start() }
    }
}
