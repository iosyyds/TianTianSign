//
//  TianTianSignApp.swift
//  TianTianSign
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
        }
    }
}
