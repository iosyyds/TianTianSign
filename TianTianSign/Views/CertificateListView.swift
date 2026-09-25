//
//  CertificateListView.swift
//  TianTianSign
//

import SwiftUI
import UniformTypeIdentifiers

struct CertificateListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false
    @State private var password = ""
    @State private var pendingURL: URL?

    var body: some View {
        NavigationStack {
            List {
                if appState.certificates.isEmpty {
                    ContentUnavailableView("还没有证书",
                        systemImage: "person.badge.key",
                        description: Text("点击右上角 + 导入你的 .p12 证书"))
                }
                ForEach(appState.certificates) { c in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle().fill(c.statusColor).frame(width: 10, height: 10)
                            Text(c.commonName).font(.headline)
                            Spacer()
                            Text(c.certType.rawValue).font(.caption).padding(3)
                                .background(.quaternary).cornerRadius(4)
                        }
                        Text("团队：\(c.teamName) (\(c.teamID))").font(.caption)
                        Text("有效期至：\(c.validUntil.formatted(date: .abbreviated, time: .omitted)) · 剩 \(c.daysRemaining) 天")
                            .font(.caption).foregroundColor(c.statusColor)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    appState.certificates.remove(atOffsets: offsets)
                }
            }
            .navigationTitle("证书")
            .toolbar { EditButton() }
            .toolbar {
                Button { showingImporter = true } label: { Image(systemName: "plus") }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data],
                          allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingURL = url
                }
            }
            .alert("输入 p12 密码", isPresented: Binding(
                get: { pendingURL != nil },
                set: { if !$0 { pendingURL = nil } }
            )) {
                SecureField("密码", text: $password)
                Button("取消", role: .cancel) { pendingURL = nil }
                Button("导入") {
                    guard let url = pendingURL else { return }
                    if let cert = try? CertificateImporter.inspect(p12: url, password: password) {
                        CertificateImporter.storePassword(password, forCertificateID: cert.id)
                        appState.certificates.append(cert)
                    }
                    pendingURL = nil; password = ""
                }
            }
        }
    }
}
