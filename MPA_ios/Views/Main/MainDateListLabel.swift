//
//  MainDateListLabel.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateListLabel: View {
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .glassEffect()
            Text("Item at \(Date(), format: Date.FormatStyle(date: .numeric, time: .standard))")
        }
        .frame(height: 60)
//        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    ScrollView {
        MainDateListLabel()
    }
    .background(Color.red.opacity(0.8))
}
