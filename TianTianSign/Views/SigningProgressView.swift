//
//  SigningProgressView.swift
//  TianTianSign
//

import SwiftUI

struct SigningProgressView: View {
    @ObservedObject var viewModel: SigningViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.task.progress) {
                        Text(viewModel.task.state.rawValue)
                            .font(.caption)
                    }
                    .padding()

                    ForEach(viewModel.task.logLines) { line in
                        HStack(alignment: .top) {
                            Text(line.date.formatted(date: .omitted, time: .standard))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(line.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(color(for: line.level))
                            Spacer()
                        }
                    }

                    if viewModel.task.state == .done, let out = viewModel.task.outputIPAURL {
                        ShareLink(item: out) {
                            Label("分享 / 安装签名后的 IPA", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
                }
                .padding()
            }
            .navigationTitle("签名进度")
        }
    }

    private func color(for level: SigningTask.LogLine.Level) -> Color {
        switch level {
        case .info: return .primary
        case .warn: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
}
