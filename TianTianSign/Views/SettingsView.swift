//
//  SettingsView.swift
//  TianTianSign
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("0.1.6").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.tiantiansign.app").foregroundColor(.secondary).font(.caption)
                    }
                }

                Section("输出目录") {
                    Text("签名后的 IPA 保存在 App 的「文件」目录中。")
                        .font(.caption).foregroundColor(.secondary)
                }

                Section {
                    Link(destination: URL(string: "https://github.com/iosyyds/TianTianSign")!) {
                        Label("GitHub 仓库", systemImage: "link")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
