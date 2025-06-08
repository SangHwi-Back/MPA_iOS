//
//  MainView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI

struct MainView: View {
    @State var replay: Bool = true
    let bottomView: () -> AnyView
    
    init(@ViewBuilder content: @escaping () -> some View = { EmptyView() }) {
        self.bottomView = { AnyView(content()) }
    }
    
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
            
            bottomView()
        }
        .navigationTitle("Contents")
    }
}

#Preview {
    MainView {
        Text("Additional Content")
    }
}
