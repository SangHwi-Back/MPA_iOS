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
    let persistence = Persistence()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .productRepository(ProductRepository(persistence: persistence))
        }
        .modelContainer(persistence.container)
    }
}
