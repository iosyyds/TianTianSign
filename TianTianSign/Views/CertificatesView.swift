//
//  CertificatesView.swift
//  TianTianSign
//

import SwiftUI

struct CertificatesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                // 证书列表
                if !appState.certificates.isEmpty {
                    Section("证书 (\(appState.certificates.count))") {
                        ForEach(appState.certificates) { c in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(c.statusColor).frame(width: 8, height: 8)
                                    Text(c.commonName).font(.subheadline).lineLimit(1)
                                    Spacer()
                                    if appState.selectedCertID == c.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.pink)
                                    }
                                }
                                Text("Team: \(c.teamName) (\(c.teamID))")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appState.selectedCertID = c.id
                                appState.save()
                            }
                        }
                        .onDelete { appState.deleteCert(at: $0) }
                    }
                }

                // 描述文件列表
                if !appState.profiles.isEmpty {
                    Section("描述文件 (\(appState.profiles.count))") {
                        ForEach(appState.profiles) { p in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(p.statusColor).frame(width: 8, height: 8)
                                    Text(p.name).font(.subheadline).lineLimit(1)
                                    Spacer()
                                    Text(p.typeLabel).font(.caption2).foregroundColor(.secondary)
                                    if appState.selectedProfileID == p.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.pink)
                                    }
                                }
                                Text("BundleID: \(p.bundleID)")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appState.selectedProfileID = p.id
                                appState.save()
                            }
                        }
                        .onDelete { appState.deleteProfile(at: $0) }
                    }
                }

                // 空状态
                if appState.certificates.isEmpty && appState.profiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                        Text("没有证书")
                            .font(.headline)
                        Text("导入 p12 证书和描述文件开始签名")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showingAdd = true
                        } label: {
                            Text("导入证书")
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
                }
            }
            .navigationTitle("证书")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddCertSheet()
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

struct AddCertSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingP12 = false
    @State private var showingProfile = false
    @State private var p12URL: URL?
    @State private var profileURL: URL?
    @State private var password = ""
    @State private var errorMsg: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("选择文件") {
                    Button {
                        showingP12 = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.ellipsis").foregroundColor(.pink)
                            Text(p12URL?.lastPathComponent ?? "选择 .p12 证书文件")
                                .lineLimit(1)
                            Spacer()
                        }
                    }

                    Button {
                        showingProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text").foregroundColor(.blue)
                            Text(profileURL?.lastPathComponent ?? "选择 .mobileprovision 描述文件")
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }

                Section("p12 密码") {
                    SecureField("输入密码（无密码留空）", text: $password)
                }

                Section {
                    Button {
                        doImport()
                    } label: {
                        HStack {
                            Spacer()
                            if isWorking {
                                ProgressView()
                            } else {
                                Text("导入")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(p12URL == nil || isWorking)
                }
            }
            .navigationTitle("导入证书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showingP12) {
                FilePicker(types: [.p12File]) { urls in
                    p12URL = urls.first
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingProfile) {
                FilePicker(types: [.mobileprovisionFile]) { urls in
                    profileURL = urls.first
                }
                .ignoresSafeArea()
            }
            .alert("错误", isPresented: Binding(get: { errorMsg != nil }, set: { if !$0 { errorMsg = nil } })) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    private func doImport() {
        guard let p12URL = p12URL else { return }
        isWorking = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 导入 p12
                let cert = try CertificateImporter.import(p12: p12URL, password: password)

                // 导入描述文件（可选）
                var profile: ProvisioningProfile? = nil
                if let purl = profileURL {
                    do {
                        profile = try ProfileImporter.import(srcURL: purl)
                    } catch {
                        // 描述文件失败不阻止
                    }
                }

                DispatchQueue.main.async {
                    appState.addCert(cert)
                    if let p = profile { appState.addProfile(p) }
                    isWorking = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isWorking = false
                    errorMsg = error.localizedDescription
                }
            }
        }
    }
}
