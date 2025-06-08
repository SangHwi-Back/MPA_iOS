//
//  MainDateListLabel.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateListLabel: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
            Text("Item at \(Date(), format: Date.FormatStyle(date: .numeric, time: .standard))")
        }
        .frame(height: 60)
    }
}

#Preview {
    MainDateListLabel()
}
