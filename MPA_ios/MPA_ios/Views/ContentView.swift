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
    @Environment(\.productRepository) private var repository
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var path: [Product] = []
    @State private var modalState = ModalState()
    @State private var hingeStatus: DeviceHingeStatus?
    @State private var selectedTab: ContentTab = .today
    
    var isDeviceiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    var isDeviceiPhoneDuo: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
        && UIDevice.current.name.contains("Duo")
    }
    
    var contentEnvironment: ContentsEnvironment {
        // iPad 일 경우
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .navigationSplit
        }
        // iPhone Duo 일 경우
        else if isDeviceiPhoneDuo {
            if horizontalSizeClass == .compact && verticalSizeClass == .compact {
                return .navigationSplit
            }
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                return .horizontalDuoSplit
            }
            else {
                return .generalVertical
            }
        }
        // iPhone 일 경우
        else {
            return .generalVertical
        }
    }
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘", image: iconName(for: .today), value: ContentTab.today) {
                todayTabContent
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

    @ViewBuilder
    private var todayTabContent: some View {
        switch contentEnvironment {
        case .horizontalDuoSplit:
            iphoneDuoSplitView
        case .verticalDuoOverlay:
            iphoneDuoOverlayView
        case .navigationSplit:
            navigationSplitView
        case .generalVertical:
            navigationContentView
        }
    }

    private func iconName(for tab: ContentTab) -> String {
        tab.rawValue + (selectedTab == tab ? "_selected" : "")
    }
    
    @ViewBuilder
    private var iphoneDuoSplitView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            } secondary: {
                navigationStackWithDestination
            }
            .arrangementViewStyle(.split)
            .onHingeChange { _, newContext in
                self.hingeStatus = getHingeStatus(from: newContext.hinge?.status)
            }
        } else {
            navigationContentView
        }
    }
    
    @ViewBuilder
    private var iphoneDuoOverlayView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                navigationStackWithDestination
            } secondary: {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            }
            .arrangementViewStyle(.overlay)
            .onHingeChange { _, newContext in
                self.hingeStatus = getHingeStatus(from: newContext.hinge?.status)
            }
        } else {
            navigationContentView
        }
    }
    
    /// - Contents
    private var navigationStackWithDestination: some View {
        NavigationStack(path: $path) {
            MainView()
                .addToolbar(MainDateListViewModel(repository: repository), path: $path)
                .padding(.horizontal, 20)
        }
        .navigationDestination(for: Product.self) { product in
            DailyJournalView(repository: repository, entry: product)
                .environment(\.journalPaths, $path)
        }
    }
    
    @ViewBuilder
    private var navigationSplitView: some View {
        NavigationSplitView {
            MainDateList(repository: repository, $path)
                .modelContainer(for: Product.self, inMemory: true)
        } detail: {
            navigationStackWithDestination
                .addToolbar(MainDateListViewModel(repository: repository), path: $path)
        }
    }
    
    @ViewBuilder
    private var navigationContentView: some View {
        NavigationStack(path: $path) {
            ScrollView { VStack(spacing: 0) {
                MainView()
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
                    .addToolbar(MainDateListViewModel(repository: repository), path: $path)
            }}
            .navigationDestination(for: Product.self) { product in
                DailyJournalView(repository: repository, entry: product)
                    .environment(\.journalPaths, $path)
            }
        }
    }
    
    @available(anyAppleOS 27.1, *)
    private func getHingeStatus(from status: DeviceHinge.Status?) -> DeviceHingeStatus? {
        switch status {
        case .closed: return .closed
        case .fullyOpen: return .fullyOpen
        case .partiallyOpen: return .partiallyOpen
        default: return nil
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
        }
    }
}

#Preview("데이터 있음") {
    ContentView()
        .productRepository(MockProductRepository(withSampleData: true))
}
