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
    @State private var hingeStatus: DeviceHingeStatus?
    
    @State private var productViewModel = ProductViewModel(repository: SwiftDataProductRepository(context: Persistence.shared.container.mainContext))
    @State private var journalViewModel = JournalViewModel(repository: SwiftDataJournalRepository(context: Persistence.shared.container.mainContext))
    @State private var homeViewModel = HomeViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    
    
    var isDeviceiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    var isDeviceiPhoneDuo: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
        && UIDevice.current.name.contains("Duo")
    }
    
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
            } else if #available(anyAppleOS 27.1, *) {
                contents
                    .onHingeChange { _, newContext in
                        self.hingeStatus = getHingeStatus(from: newContext.hinge?.status)
                    }
            } else {
                contents
            }
        }
        .modelContainer(Persistence.shared.container)
    }
    
    var contents: some View {
        ContentView()
            .environment(productViewModel)
            .environment(journalViewModel)
            .environment(homeViewModel)
            .environment(settingsViewModel)
            .environment(\.isDeviceiPad, isDeviceiPad)
            .environment(\.isDeviceiPhoneDuo, isDeviceiPhoneDuo)
            .environment(\.hingeStatus, hingeStatus)
            .transition(.opacity)
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
