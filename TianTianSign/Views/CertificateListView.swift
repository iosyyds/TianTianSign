//
//  CertificatesView.swift
//  TianTianSign
//  Feather-style certificates list with add sheet.
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
                    ContentUnavailableView {
                        Label("没有证书", systemImage: "questionmark.folder")
                    } description: {
                        Text("导入你的第一个证书开始签名")
                    } actions: {
                        Button {
                            showingAdd = true
                        } label: {
                            Label("导入", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
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
                        }
                    }
                    .onDelete { offsets in
                        appState.certificates.remove(atOffsets: offsets)
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

    var body: some View {
        NavigationStack {
            Form {
                Section("文件") {
                    Button {
                        showingP12 = true
                    } label: {
                        Label(p12URL?.lastPathComponent ?? "导入证书 (.p12)",
                              systemImage: "person.badge.key")
                    }
                    Button {
                        showingProfile = true
                    } label: {
                        Label(profileURL?.lastPathComponent ?? "导入描述文件 (.mobileprovision)",
                              systemImage: "doc.text")
                    }
                }

                Section("密码") {
                    SecureField("p12 密码（无密码留空）", text: $password)
                } footer: {
                    Text("输入私钥对应的密码，如果没有密码请留空。")
                }

                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            Text("保存")
                            Spacer()
                        }
                    }
                    .disabled(p12URL == nil || profileURL == nil)
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
                    if let url = urls.first {
                        importProfile(url)
                    }
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

    private func importProfile(_ url: URL) {
        do {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: tmp.path) {
                try FileManager.default.removeItem(at: tmp)
            }
            try FileManager.default.copyItem(at: url, to: tmp)
            if let p = try? ProfileParser.parse(fileURL: tmp) {
                appState.profiles.append(p)
            }
        } catch {
            errorMsg = "描述文件解析失败：\(error.localizedDescription)"
        }
    }

    private func save() {
        guard let p12URL = p12URL else { return }
        do {
            if let cert = try? CertificateImporter.inspect(p12: p12URL, password: password) {
                CertificateImporter.storePassword(password, forCertificateID: cert.id)
                appState.certificates.append(cert)
                dismiss()
            } else {
                errorMsg = "p12 解析失败，请检查密码"
            }
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
