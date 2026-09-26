//
//  RootView.swift
//  TianTianSign
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("应用", systemImage: "app.fill")
                }

            CertificatesView()
                .tabItem {
                    Label("证书", systemImage: "person.badge.key")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .tint(.pink)
    }
}
