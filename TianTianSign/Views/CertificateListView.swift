//
//  CertificatesView.swift
//  TianTianSign
//  Feather-style certificate management with p12 + mobileprovision import.
//

import SwiftUI
import UniformTypeIdentifiers

struct CertificatesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingP12Picker = false
    @State private var showingProfilePicker = false
    @State private var pendingP12URL: URL?
    @State private var pendingProfileURL: URL?
    @State private var password = ""
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            List {
                Section("证书文件 (.p12)") {
                    if let url = pendingP12URL {
                        LabeledContent("已选择", value: url.lastPathComponent)
                    } else {
                        Button {
                            showingP12Picker = true
                        } label: {
                            Label("导入证书文件", systemImage: "person.badge.key")
                        }
                    }
                }

                Section("描述文件 (.mobileprovision)") {
                    if let url = pendingProfileURL {
                        LabeledContent("已选择", value: url.lastPathComponent)
                    } else {
                        Button {
                            showingProfilePicker = true
                        } label: {
                            Label("导入描述文件", systemImage: "doc.text")
                        }
                    }
                }

                Section("密码") {
                    SecureField("p12 密码（无密码留空）", text: $password)
                }

                Section {
                    Button {
                        importCertificate()
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存证书", systemImage: "checkmark.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(pendingP12URL == nil || pendingProfileURL == nil)
                }

                if !appState.certificates.isEmpty {
                    Section("已导入的证书") {
                        ForEach(appState.certificates) { c in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(c.statusColor).frame(width: 8, height: 8)
                                    Text(c.commonName).font(.headline)
                                    Spacer()
                                }
                                Text("团队：\(c.teamName) (\(c.teamID))").font(.caption)
                                Text("有效期至：\(c.validUntil.formatted(date: .abbreviated, time: .omitted)) · 剩 \(c.daysRemaining) 天")
                                    .font(.caption).foregroundColor(c.statusColor)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { offsets in
                            appState.certificates.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("证书")
            .sheet(isPresented: $showingP12Picker) {
                FilePicker(allowedContentTypes: [.p12], allowsMultiple: false) { urls in
                    guard let url = urls.first else { return }
                    pendingP12URL = url
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingProfilePicker) {
                FilePicker(allowedContentTypes: [.mobileProvision], allowsMultiple: false) { urls in
                    guard let url = urls.first else { return }
                    pendingProfileURL = url
                }
                .ignoresSafeArea()
            }
            .alert("错误", isPresented: Binding(
                get: { errorMsg != nil },
                set: { if !$0 { errorMsg = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    private func importCertificate() {
        guard let p12URL = pendingP12URL else { return }
        do {
            if let cert = try? CertificateImporter.inspect(p12: p12URL, password: password) {
                CertificateImporter.storePassword(password, forCertificateID: cert.id)
                appState.certificates.append(cert)
                pendingP12URL = nil
                pendingProfileURL = nil
                password = ""
            } else {
                errorMsg = "p12 解析失败，请检查密码或文件"
            }
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
