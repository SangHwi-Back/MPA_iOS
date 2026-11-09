//
//  ContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI

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
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @Environment(\.isDeviceiPhoneDuo)
    private var isDeviceiPhoneDuo
    @Environment(\.productRepository)
    private var productRepository
    
    @StateObject private var journalViewModel = JournalViewModel()
    
    var contentsEnvironment: ContentsEnvironment {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .navigationSplit
        } else if isDeviceiPhoneDuo {
            if horizontalSizeClass == .compact && verticalSizeClass == .compact {
                return .navigationSplit
            }
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                return .horizontalDuoSplit
            } else {
                return .generalVertical
            }
        } else {
            return .generalVertical
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘", image: iconName(for: .today), value: ContentTab.today) {
                HomeView(viewModel: journalViewModel)
                    .environment(\.contentsEnvironment, contentsEnvironment)
            }
            Tab("기록", image: iconName(for: .journal), value: ContentTab.journal) {
                JournalHomeView(viewModel: journalViewModel)
            }
            Tab("원칙", image: iconName(for: .principles), value: ContentTab.principles) {
                PrincipalHomeView()
            }
            Tab("설정", image: iconName(for: .settings), value: ContentTab.settings) {
                SettingsHomeView()
            }
        }
        .environment(\.showModal, modalState)
        .onTapGesture {
            self.modalState.modalType = .none
        }
        .overlay {
            getModalView()
        }
        .onAppear {
            journalViewModel.productRepository = productRepository
        }
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
            .background {
                ConcentricRectangle()
                    .fill(Color.black.opacity(0.5))
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview("데이터 있음") {
    ContentView()
        .productRepository(MockProductRepository(withSampleData: true))
}
