//
//  ContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var path: [Product] = []
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                MainDateList($path)
                    .modelContainer(for: Product.self, inMemory: true)
            } detail: {
                NavigationStack(path: $path) {
                    MainView()
                        .padding(.horizontal, 20)
                }
                .navigationDestination(for: Product.self) { _ in
                    DailyJournalView()
                        .environment(\.journalPaths, path)
                }
            }
        } else {
            NavigationStack(path: $path) {
                ScrollView { VStack(spacing: 15) {
                    MainView()
                    MainDateList($path)
                        .modelContainer(for: Product.self, inMemory: true)
                }}
                .padding(.horizontal, 20)
                .navigationDestination(for: Product.self) { _ in
                    DailyJournalView()
                        .environment(\.journalPaths, path)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
