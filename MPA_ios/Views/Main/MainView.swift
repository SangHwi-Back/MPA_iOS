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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThickMaterial)
            
            Text("Hello This is \(DateFormatter.common.string(from: Date()))")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 55)
    }
    
    var body: some View {
        VStack {
            titleTextView
            GeometryReader { geo in
                BubbleView(size: CGSize(width: geo.size.width, height: mainViewHeight))
                    .background(.ultraThinMaterial)
            }
            .frame(height: mainViewHeight)
            Spacer()
        }
        .navigationTitle("Contents")
        
    }
}

#Preview {
    MainView()
}
