//
//  IPALibraryView.swift
//  TianTianSign
//

import SwiftUI
import UniformTypeIdentifiers

struct IPALibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false

    var body: some View {
        NavigationStack {
            List {
                if appState.library.isEmpty {
                    ContentUnavailableView("资料库空空如也",
                        systemImage: "shippingbox",
                        description: Text("从文件 App 导入 IPA，或在「签名」页直接选"))
                }
                ForEach(appState.library) { ipa in
                    VStack(alignment: .leading) {
                        Text(ipa.appName).font(.headline)
                        Text("\(ipa.bundleID) · v\(ipa.version)(\(ipa.buildVersion)) · \(ipa.sizeText)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }.onDelete { appState.library.remove(atOffsets: $0) }
            }
            .navigationTitle("IPA 资料库")
            .toolbar {
                Button { showingImporter = true } label: { Image(systemName: "plus") }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data],
                          allowsMultipleSelection: true) { result in
                guard case .success(let urls) = result else { return }
                for url in urls {
                    if let parsed = try? IPAParser.parse(ipazip: url) {
                        appState.library.append(parsed)
                    }
                }
            }
        }
    }
}
