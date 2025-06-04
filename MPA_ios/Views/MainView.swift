//
//  MainView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI

struct MainView: View {
    @State var replay: Bool = true
    
    var titleTextView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                
            Text("Hello This is \(DateFormatter.common.string(from: Date()))")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 55)
        .padding(.horizontal, 20)
    }
    
    var body: some View {
        VStack {
            titleTextView
            BubbleView()
                .padding(.horizontal, 20)
        }
        .navigationTitle("Contents")
    }
}

#Preview {
    MainView()
}
