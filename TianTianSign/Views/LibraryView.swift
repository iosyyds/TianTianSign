//
//  LibraryView.swift
//  TianTianSign
//  应用列表 + 签名
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImport = false
    @State private var pickedIPA: IPAFile?
    @State private var newBundleID = ""
    @State private var newName = ""
    @State private var taskRunner: SigningViewModel?
    @State private var showingSigning = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            List {
                if pickedIPA == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                        Text("导入 IPA 文件")
                            .font(.headline)
                        Text("点击右上角 + 或下方按钮选择 IPA")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button {
                            showingImport = true
                        } label: {
                            Text("选择 IPA")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.pink)
                                .cornerRadius(22)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .listRowSeparator(.hidden)
                } else {
                    // 已选应用
                    Section("应用") {
                        HStack(spacing: 12) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.pink)
                            VStack(alignment: .leading) {
                                Text(pickedIPA!.appName).font(.headline)
                                Text("\(pickedIPA!.bundleID) · \(pickedIPA!.sizeText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    // 证书选择
                    Section("签名证书") {
                        Picker("证书", selection: $appState.selectedCertID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.certificates) { c in
                                Text(c.commonName).tag(UUID?.some(c.id))
                            }
                        }
                        Picker("描述文件", selection: $appState.selectedProfileID) {
                            Text("未选择").tag(UUID?.none)
                            ForEach(appState.profiles) { p in
                                Text("\(p.name) (\(p.typeLabel))").tag(UUID?.some(p.id))
                            }
                        }

                        if appState.certificates.isEmpty {
                            Text("请先到「证书」页导入 p12 证书")
                                .font(.caption).foregroundColor(.orange)
                        }
                        if appState.profiles.isEmpty {
                            Text("请先到「证书」页导入描述文件")
                                .font(.caption).foregroundColor(.orange)
                        }
                    }

                    // 修改
                    Section("修改（可选）") {
                        TextField("新 Bundle ID", text: $newBundleID)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        TextField("新显示名称", text: $newName)
                    }

                    // 签名按钮
                    Section {
                        Button {
                            startSign()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "signature")
                                Text("开始签名")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(appState.selectedCert == nil || appState.selectedProfile == nil)
                    }
                }
            }
            .navigationTitle("应用")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingImport = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingImport) {
                FilePicker(types: [.ipaFile]) { urls in
                    guard let u = urls.first else { return }
                    do {
                        pickedIPA = try IPAParser.parse(ipaURL: u)
                    } catch {
                        errorMsg = error.localizedDescription
                    }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingSigning) {
                if let runner = taskRunner { SigningProgressView(viewModel: runner) }
            }
            .alert("错误", isPresented: Binding(get: { errorMsg != nil }, set: { if !$0 { errorMsg = nil } })) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    private func startSign() {
        guard let ipa = pickedIPA,
              let cert = appState.selectedCert,
              let profile = appState.selectedProfile else { return }

        let task = SigningTask(
            id: UUID(),
            ipaURL: ipa.fileURL,
            ipaName: ipa.fileName,
            cert: cert,
            profile: profile,
            newBundleID: newBundleID.isEmpty ? nil : newBundleID,
            newName: newName.isEmpty ? nil : newName
        )
        taskRunner = SigningViewModel(task: task)
        showingSigning = true
        Task { await taskRunner?.start() }
    }
}
