//
//  ProfileListView.swift
//  TianTianSign
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false

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
                        if !p.provisionsDevices.isEmpty {
                            Text("绑定 \(p.provisionsDevices.count) 台设备")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 4)
                }.onDelete { appState.profiles.remove(atOffsets: $0) }
            }
            .navigationTitle("描述文件")
            .toolbar {
                Button { showingImporter = true } label: { Image(systemName: "plus") }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "mobileprovision") ?? .data],
                          allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first,
                      let p = try? ProfileParser.parse(fileURL: url) else { return }
                appState.profiles.append(p)
            }
        }
    }
}
