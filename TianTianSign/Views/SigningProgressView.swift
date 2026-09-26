//
//  SigningProgressView.swift
//  TianTianSign
//

import SwiftUI

struct SigningProgressView: View {
    @ObservedObject var viewModel: SigningViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("进度") {
                    ProgressView(value: viewModel.task.progress)
                    Text("状态：\(statusText)")
                        .font(.caption)
                }

                Section("日志") {
                    ForEach(viewModel.task.logLines) { line in
                        Text(line.message)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .navigationTitle("签名中")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.task.state == .done || viewModel.task.state == .failed {
                        Button("完成") { dismiss() }
                    }
                }
            }
        }
    }

    var statusText: String {
        switch viewModel.task.state {
        case .idle: return "等待"
        case .unpacking: return "解压中"
        case .signing: return "签名中"
        case .done: return "完成"
        case .failed: return "失败"
        }
    }
}
