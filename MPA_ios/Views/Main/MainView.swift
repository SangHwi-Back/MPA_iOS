//
//  MainView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI
import FoundationModels

struct MainView: View {
    @State var replay: Bool = true
    @State var mainViewHeight: CGFloat = 280
    
    private var model = SystemLanguageModel.default
    
    var body: some View {
        ScrollView {
            AppleIntelligenceStatusView()
                .padding(.horizontal)
                .padding(.bottom, 20)

            BubbleView(height: mainViewHeight)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .navigationTitle("Contents")
    }
}

#Preview {
    MainView()
}
