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
        Text("Item at \(Date(), format: Date.FormatStyle(date: .numeric, time: .standard))")
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .glassEffect(.regular.interactive(), in: Capsule())
    }
}

#Preview {
    ScrollView {
        MainDateListLabel()
    }
    .background(Color.black)
}
