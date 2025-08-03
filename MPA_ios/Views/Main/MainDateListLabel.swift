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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            Text("Item at \(Date(), format: Date.FormatStyle(date: .numeric, time: .standard))")
        }
        .frame(height: 60)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    MainDateListLabel()
}
