//
//  RootView.swift
//  TianTianSign
//  Feather-style standard TabView.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("资料库", systemImage: "square.grid.2x2")
                }
                .tag(0)

            CertificatesView()
                .tabItem {
                    Label("证书", systemImage: "person.text.rectangle")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.2")
                }
                .tag(2)
        }
        .tint(.pink)
    }
}
