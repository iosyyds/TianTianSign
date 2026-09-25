//
//  TianTianSignApp.swift
//  TianTianSign
//
//  甜甜签 · iOS IPA 重签名工具 App 入口
//

import SwiftUI

@main
struct TianTianSignApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(.pink)
                .preferredColorScheme(.light)
        }
    }
}
