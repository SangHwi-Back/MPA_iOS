//
//  ContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI

enum ContentsEnvironment {
    case navigationSplit
    /// iPhone Duo Split + 가로
    case horizontalDuoSplit
    /// iPhone Duo 오버레이 + 세로
    case verticalDuoOverlay
    /// iPhone 세로 형태 기준
    case generalVertical
}

enum DeviceHingeStatus {
    case closed
    case partiallyOpen
    case fullyOpen
}

enum ContentTab: String, CaseIterable, Identifiable, Hashable {
    case today = "tab_today"
    case journal = "tab_journal"
    case principles = "tab_principles"
    case settings = "tab_settings"

    var id: String { rawValue }
}

struct ContentView: View {
    @State private var modalState = ModalState()
    @State private var selectedTab: ContentTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘", image: iconName(for: .today), value: ContentTab.today) {
                TodayHomeView()
            }

            Tab("기록", image: iconName(for: .journal), value: ContentTab.journal) {
                Text("기록")
            }
            Tab("원칙", image: iconName(for: .principles), value: ContentTab.principles) {
                Text("원칙")
            }
            Tab("설정", image: iconName(for: .settings), value: ContentTab.settings) {
                Text("설정")
            }
        }
        .environment(\.showModal, modalState)
        .onTapGesture {
            self.modalState.modalType = .none
        }
        .overlay {
            getModalView()
        }
        .background {
            ConcentricRectangle()
                .fill(dimColor)
                .ignoresSafeArea()
        }
    }

    private var dimColor: Color {
        modalState.modalType == .none ? Color.clear : Color.black.opacity(0.5)
    }

    private func iconName(for tab: ContentTab) -> String {
        tab.rawValue + (selectedTab == tab ? "_selected" : "")
    }
    
    @ViewBuilder
    func getModalView() -> some View {
        switch modalState.modalType {
        case .none:
            EmptyView()
        case .common(let model):
            CommonModalView(model) {
                self.modalState.modalType = .none
            }
        }
    }
}

#Preview("데이터 있음") {
    ContentView()
        .productRepository(MockProductRepository(withSampleData: true))
}
