//
//  SettingsView.swift
//  TianTianSign
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("关于甜甜签") {
                    LabeledContent("版本", value: "0.1.0 (WIP)")
                    LabeledContent("底层引擎", value: "zsign (vendored)")
                    NavigationLink("使用手册") { Text("见 docs/usage.md").padding() }
                    NavigationLink("开源协议") { Text("MIT · 见 LICENSE").padding() }
                }
                Section("数据") {
                    Text("所有证书、描述文件和 IPA 仅保存在本设备沙盒中，不会上传任何服务器。")
                        .font(.caption).foregroundColor(.secondary)
                }
                Section {
                    Link(destination: URL(string: "https://github.com/iosyyds/TianTianSign")!) {
                        Label("GitHub 仓库", systemImage: "link")
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}
