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
    @State private var isLaunchProcessing: Bool = true
    
    let persistence = Persistence()

    var body: some Scene {
        WindowGroup {
            if isLaunchProcessing {
                Image("LaunchScreenAfter")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            self.isLaunchProcessing = false
                        }
                    }
            } else {
                ContentView()
                    .productRepository(ProductRepository(persistence: persistence))
                    .transition(.opacity)
            }
        }
        .modelContainer(persistence.container)
    }
}
