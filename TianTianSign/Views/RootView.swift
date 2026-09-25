//
//  RootView.swift
//  TianTianSign
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("签名", systemImage: "donut.fill") }
            CertificateListView()
                .tabItem { Label("证书", systemImage: "person.badge.shield.checkmark") }
            ProfileListView()
                .tabItem { Label("描述文件", systemImage: "doc.badge.ellipsis") }
            IPALibraryView()
                .tabItem { Label("资料库", systemImage: "shippingbox") }
            SettingsView()
                .tabItem { Label("我的", systemImage: "gearshape") }
        }
        .tint(.pink)
    }
}

#Preview { RootView().environmentObject(AppState.shared) }
