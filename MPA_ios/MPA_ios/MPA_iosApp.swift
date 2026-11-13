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
    
    @State private var productViewModel: ProductViewModel
    @State private var journalViewModel: JournalViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var settingsViewModel = SettingsViewModel()

    init() {
        let context = Persistence.shared.container.mainContext
        // One repository shared by 오늘 and 기록, so both screens see the same journals.
        _productViewModel = State(initialValue: ProductViewModel(repository: SwiftDataProductRepository(context: context)))
        
        let journalRepository = SwiftDataJournalRepository(context: context)
        _journalViewModel = State(initialValue: JournalViewModel(repository: journalRepository))
        
        _homeViewModel = State(initialValue: HomeViewModel(repository: journalRepository))
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
                contents.onHingeChange { _, newContext in
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
