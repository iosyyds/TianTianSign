//
//  CertificatesView.swift
//  TianTianSign
//  证书列表 + 添加证书 sheet
//

import SwiftUI
import UniformTypeIdentifiers

struct CertificatesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if appState.certificates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("没有证书")
                            .font(.headline)
                        Text("导入你的 p12 证书和描述文件开始签名")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingAdd = true
                        } label: {
                            Text("导入证书")
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
                } else {
                    ForEach(appState.certificates) { c in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Circle().fill(c.statusColor).frame(width: 10, height: 10)
                                Text(c.commonName).font(.headline)
                                Spacer()
                                if appState.selectedCertificateID == c.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.pink)
                                }
                            }
                            Text("团队：\(c.teamName) (\(c.teamID))")
                                .font(.caption).foregroundColor(.secondary)
                            Text("有效期至：\(c.validUntil.formatted(date: .abbreviated, time: .omitted)) · 剩 \(c.daysRemaining) 天")
                                .font(.caption).foregroundColor(c.statusColor)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.selectedCertificateID = c.id
                            appState.save()
                        }
                    }
                    .onDelete { offsets in
                        appState.deleteCertificate(at: offsets)
                    }
                }

                // 描述文件 section
                if !appState.profiles.isEmpty {
                    Section("描述文件") {
                        ForEach(appState.profiles) { p in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(p.statusColor).frame(width: 8, height: 8)
                                    Text(p.appIDName).font(.subheadline)
                                    Spacer()
                                    Text(p.typeBadge).font(.caption).foregroundColor(.secondary)
                                }
                                Text("BundleID: \(p.bundleID)")
                                    .font(.caption2).foregroundColor(.secondary)
                                Text("有效期至 \(p.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundColor(p.statusColor)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appState.selectedProfileID = p.id
                                appState.save()
                            }
                        }
                        .onDelete { offsets in
                            appState.deleteProfile(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("证书")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                CertificateAddSheet()
                    .presentationDetents([.medium])
            }
        }
    }
}

struct CertificateAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showingP12 = false
    @State private var showingProfile = false
    @State private var p12URL: URL?
    @State private var profileURL: URL?
    @State private var password = ""
    @State private var errorMsg: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingP12 = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.key")
                                .foregroundColor(.pink)
                            Text(p12URL?.lastPathComponent ?? "选择证书 (.p12)")
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    Button {
                        showingProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(profileURL?.lastPathComponent ?? "选择描述文件 (.mobileprovision)")
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                } header: {
                    Text("文件")
                }

                Section {
                    SecureField("p12 密码（无密码留空）", text: $password)
                } header: {
                    Text("密码")
                } footer: {
                    Text("输入 p12 对应的密码，如果没有密码请留空。")
                }

                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("保存证书")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(p12URL == nil || isSaving)
                }
            }
            .navigationTitle("新证书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showingP12) {
                FilePicker(allowedContentTypes: [.p12], allowsMultipleSelection: false) { urls in
                    p12URL = urls.first
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingProfile) {
                FilePicker(allowedContentTypes: [.mobileProvision], allowsMultipleSelection: false) { urls in
                    profileURL = urls.first
                }
                .ignoresSafeArea()
            }
            .alert("错误", isPresented: Binding(
                get: { errorMsg != nil }, set: { if !$0 { errorMsg = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    private func save() {
        guard let p12URL = p12URL else { return }
        isSaving = true

        // 在后台线程解析
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try CertificateImporter.inspect(p12: p12URL, password: password)

                // 保存密码到 Keychain
                CertificateImporter.storePassword(password, forCertificateID: result.cert.id)

                // 处理描述文件（可选但推荐）
                var parsedProfile: ProvisioningProfile? = nil
                if let profURL = profileURL {
                    do {
                        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(profURL.lastPathComponent)
                        try? FileManager.default.removeItem(at: tmp)
                        try FileManager.default.copyItem(at: profURL, to: tmp)
                        var p = try ProfileParser.parse(fileURL: tmp)
                        // 复制到持久目录
                        let profDest = appState.profilesDir.appendingPathComponent("\(p.id.uuidString).mobileprovision")
                        try? FileManager.default.removeItem(at: profDest)
                        try FileManager.default.copyItem(at: tmp, to: profDest)
                        p.fileURL = profDest
                        parsedProfile = p
                    } catch {
                        // 描述文件失败不阻止证书保存
                    }
                }

                DispatchQueue.main.async {
                    appState.addCertificate(result.cert)
                    if let p = parsedProfile {
                        appState.addProfile(p)
                    }
                    isSaving = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    errorMsg = "导入失败：\(error.localizedDescription)"
                }
            }
        }
    }
}
