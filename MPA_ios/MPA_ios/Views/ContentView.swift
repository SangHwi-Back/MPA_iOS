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
    
    private var isTabBarVisible: Bool {
        !(selectedTab == .journal && journalViewModel.isSearchActive)
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
        ZStack {
            tabPage(.today) {
                HomeView(viewModel: journalViewModel)
                    .environment(\.contentsEnvironment, contentsEnvironment)
            }
            tabPage(.journal) {
                JournalView(viewModel: journalViewModel)
            }
            tabPage(.principles) {
                PrincipleView()
            }
            tabPage(.settings) {
                SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible && horizontalSizeClass != .regular {
                MPATabBar(selectedTab: $selectedTab, isVertical: false, onReselect: reselect)
                    .padding(.horizontal, 20)
                    .padding(.bottom, -10)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isTabBarVisible && horizontalSizeClass == .regular {
                MPATabBar(selectedTab: $selectedTab, isVertical: true, onReselect: reselect)
                    .padding(19)
                    .ignoresSafeArea(.container, edges: .bottom)
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
