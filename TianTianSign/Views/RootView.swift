//
//  RootView.swift
//  TianTianSign
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case sign, cert, profile, library, me

    var title: String {
        switch self {
        case .sign: return "签名"
        case .cert: return "证书"
        case .profile: return "描述文件"
        case .library: return "资料库"
        case .me: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .sign: return "checkmark.seal.fill"
        case .cert: return "person.badge.shield.checkmark.fill"
        case .profile: return "doc.text.fill"
        case .library: return "shippingbox.fill"
        case .me: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: TabItem = .sign

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .sign: HomeView()
                case .cert: CertificateListView()
                case .profile: ProfileListView()
                case .library: IPALibraryView()
                case .me: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }

            FloatingCapsuleTabBar(selected: $selected)
                .padding(.horizontal, 20)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = item
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selected == item ? .white : .pink.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected == item {
                            Capsule()
                                .fill(Color.pink)
                                .shadow(color: .pink.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                }
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview { RootView().environmentObject(AppState.shared) }
