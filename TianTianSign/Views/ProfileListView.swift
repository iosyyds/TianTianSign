//
//  ProfileListView.swift
//  TianTianSign
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            List {
                if appState.profiles.isEmpty {
                    ContentUnavailableView("还没有描述文件",
                        systemImage: "doc.badge.ellipsis",
                        description: Text("导入 .mobileprovision，App 重签时会内嵌它"))
                }
                ForEach(appState.profiles) { p in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle().fill(p.statusColor).frame(width: 10, height: 10)
                            Text(p.bundleID).font(.headline)
                            Spacer()
                            Text(p.typeBadge)
                                .font(.caption).padding(3)
                                .background(.quaternary).cornerRadius(4)
                        }
                        Text("Team：\(p.teamName) (\(p.teamID))").font(.caption)
                        Text("过期：\(p.expirationDate.formatted(date: .abbreviated, time: .omitted)) · 剩 \(p.daysRemaining) 天")
                            .font(.caption).foregroundColor(p.statusColor)
                    }.padding(.vertical, 4)
                }.onDelete { appState.profiles.remove(atOffsets: $0) }
            }
            .navigationTitle("描述文件")
            .toolbar {
                Button { showingImporter = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showingImporter) {
                FilePicker(allowedContentTypes: [.data], allowsMultiple: false) { urls in
                    handleURLs(urls)
                }
            }
            .alert("提示", isPresented: Binding(
                get: { errorMsg != nil },
                set: { if !$0 { errorMsg = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMsg ?? "")
            }
        }
    }

    private func handleURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: tmp.path) { try FileManager.default.removeItem(at: tmp) }
            try FileManager.default.copyItem(at: url, to: tmp)
            if let p = try? ProfileParser.parse(fileURL: tmp) {
                appState.profiles.append(p)
            } else {
                errorMsg = "解析描述文件失败（格式不支持或文件损坏）"
            }
        } catch {
            errorMsg = "导入描述文件失败：\(error.localizedDescription)"
        }
    }
}
