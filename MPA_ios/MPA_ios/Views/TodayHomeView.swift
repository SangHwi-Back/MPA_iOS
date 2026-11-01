//
//  TodayHomeView.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI

struct TodayHomeView: View {
    @Environment(\.productRepository) private var repository
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var path: [Product] = []
    @State private var hingeStatus: DeviceHingeStatus?

    var isDeviceiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    var isDeviceiPhoneDuo: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
        && UIDevice.current.name.contains("Duo")
    }
    var contentEnvironment: ContentsEnvironment {
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

    @ViewBuilder
    var body: some View {
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

    private var navigationSplitView: some View {
        NavigationSplitView {
            MainDateList(repository: repository, $path)
                .modelContainer(for: Product.self, inMemory: true)
        } detail: {
            navigationStackWithDestination
                .addToolbar(MainDateListViewModel(repository: repository), path: $path)
        }
    }

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
}
