//
//  RootView.swift
//  TianTianSign
//  Feather-style floating capsule tab bar.
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case library, certificates, settings

    var title: String {
        switch self {
        case .library: return "资料库"
        case .certificates: return "证书"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .library: return "square.grid.2x2"
        case .certificates: return "person.text.rectangle"
        case .settings: return "gearshape.2"
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: TabItem = .library

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .library: LibraryView()
                case .certificates: CertificatesView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }

            FloatingCapsuleTabBar(selected: $selected)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .tint(.pink)
    }
}

struct FloatingCapsuleTabBar: View {
    @Binding var selected: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = item
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selected == item ? .white : .pink.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected == item {
                            Capsule()
                                .fill(Color.pink)
                                .shadow(color: .pink.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                    }
                }
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview { RootView().environmentObject(AppState.shared) }
