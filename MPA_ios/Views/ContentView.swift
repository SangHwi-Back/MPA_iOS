//
//  ContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.productRepository) private var repository
    @State private var path: [Product] = []
    @State private var modalState = ModalState()
    
    var body: some View {
        ZStack {
            navigationContent
                .environment(\.showModal, modalState)
            
            if modalState.modalType != .none {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.modalState.modalType = .none
                    }
                    .overlay {
                        getModalView()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var navigationContent: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            } detail: {
                NavigationStack(path: $path) {
                    MainView()
                        .padding(.horizontal, 20)
                }
                .navigationDestination(for: Product.self) { product in
                    DailyJournalView(repository: repository, entry: product)
                        .environment(\.journalPaths, $path)
                }
            }
        } else {
            NavigationStack(path: $path) {
                ScrollView { VStack(spacing: 0) {
                    MainView()
                    MainDateList(repository: repository, $path)
                        .modelContainer(for: Product.self, inMemory: true)
                }}
                .navigationDestination(for: Product.self) { product in
                    DailyJournalView(repository: repository, entry: product)
                        .environment(\.journalPaths, $path)
                }
            }
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
