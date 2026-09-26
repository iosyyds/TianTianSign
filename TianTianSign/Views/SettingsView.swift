//
//  SettingsView.swift
//  TianTianSign
//  Feather-style settings.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("版本", value: "0.1.5")
                    LabeledContent("签名引擎", value: "zsign")
                } header: {
                    Text("关于")
                }

                Section {
                    Text("所有证书、描述文件和 IPA 仅保存在本设备中，不会上传到任何服务器。")
                        .font(.caption).foregroundColor(.secondary)
                } header: {
                    Text("隐私")
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
