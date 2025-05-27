//
//  MyLocalMarketiOSApp.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftUI
import SwiftData

@main
struct MyLocalMarketiOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.productViewModel, ProductViewModel.defaultValue)
        }
        .modelContainer(Persistence.CacheContainer)
    }
}
