//
//  MainView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI

struct MainView: View {
    @State var replay: Bool = true
    @State var mainViewHeight: CGFloat = 280
    
    var titleTextView: some View {
        Text("Hello This is \(DateFormatter.common.string(from: Date()))")
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .glassEffect()
    }
    
    var body: some View {
        ScrollView {
            titleTextView
            BubbleView(height: mainViewHeight)
        }
        .navigationTitle("Contents")
    }
}

#Preview {
    MainView()
}
