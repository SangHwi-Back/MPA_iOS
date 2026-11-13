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

    var title: String {
        switch self {
        case .today:      return "오늘"
        case .journal:    return "기록"
        case .principles: return "원칙"
        case .settings:   return "설정"
        }
    }
}

/// Floating tab bar: a horizontal capsule on the phone and a vertical rail on the tablet.
private struct MPATabBar: View {
    @Binding var selectedTab: ContentTab
    let isVertical: Bool
    var onReselect: (ContentTab) -> Void

    var body: some View {
        let layout = isVertical ? AnyLayout(VStackLayout(spacing: 2)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(ContentTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(isVertical ? 6 : 4)
        .background(
            Capsule()
                .fill(Color.SURFACE)
                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        )
    }

    private func tabButton(_ tab: ContentTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            if isSelected { onReselect(tab) }
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(tab.rawValue + (isSelected ? "_selected" : ""))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)
            }
            .frame(width: isVertical ? 61 : nil, height: isVertical ? 60 : 56)
            .frame(maxWidth: isVertical ? nil : .infinity)
            .background {
                if isSelected {
                    Capsule().fill(Color.BRAND_CONTAINER.opacity(0.6))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ContentView: View {
    @State private var modalState = ModalState()
    @State private var selectedTab: ContentTab = .today
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @Environment(\.hingeStatus)
    private var hingeStatus
    @Environment(HomeViewModel.self)
    private var homeViewModel
    @Environment(ProductViewModel.self)
    private var productViewModel: ProductViewModel
    @Environment(JournalViewModel.self)
    private var journalViewModel: JournalViewModel
    @Environment(SettingsViewModel.self)
    private var settingsViewModel: SettingsViewModel
    
    @State private var isSettingsDetailPresented = false
    
    private var isAIAvailable: Bool {
        HomeAIStatus(connection: settingsViewModel.aiConnection).isAvailable
    }

    private func reselect(_ tab: ContentTab) {
        if tab == .journal { journalViewModel.scrollToTopSignal += 1 }
    }

    private func tabPage<Content: View>(_ tab: ContentTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(ContentTab.today.title, image: iconName(for: .today), value: .today) {
                HomeView(
                    selectedTab: $selectedTab,
                    isSettingsDetailPresented: $isSettingsDetailPresented
                )
            }
            Tab(ContentTab.journal.title, image: iconName(for: .journal), value: .journal) {
                JournalView(viewModel: journalViewModel)
            }
            // No AI: the 원칙 tab is hidden and the app becomes a plain diary (3 tabs, Part A 3.15).
            if isAIAvailable {
                Tab(ContentTab.principles.title, image: iconName(for: .principles), value: .principles) {
                    PrincipleView()
                }
            }
            Tab(ContentTab.settings.title, image: iconName(for: .settings), value: .settings) {
                SettingsView(viewModel: settingsViewModel, isDetailPresented: $isSettingsDetailPresented)
            }
        }
        .environment(\.showModal, modalState)
        .onChange(of: settingsViewModel.aiConnection, initial: true) {
            homeViewModel.aiStatus = HomeAIStatus(connection: settingsViewModel.aiConnection)
        }
        .onTapGesture {
            self.modalState.modalType = .none
        }
        .overlay {
            getModalView()
        }
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
    
    func iconName(for tab: ContentTab) -> String {
        let suffix = selectedTab == tab ? "_selected" : ""
        switch tab {
        case .today:
            return "tab_today" + suffix
        case .journal:
            return "tab_journal" + suffix
        case .principles:
            return "tab_principles" + suffix
        case .settings:
            return "tab_settings" + suffix
        }
    }
}
