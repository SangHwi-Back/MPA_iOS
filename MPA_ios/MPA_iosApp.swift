//
//  MPA_iosApp.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/3/25.
//

import SwiftUI
import SwiftData

@main
struct MPA_iosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.productViewModel, ProductViewModel.defaultValue)
        }
        .modelContainer(Persistence.CacheContainer)
    }
}
