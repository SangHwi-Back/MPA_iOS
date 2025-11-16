//
//  CustomButton.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/16/25.
//

import SwiftUI

struct CustomButton: View {
    let data: CustomButtonData
    let action: () -> Void

    init(data: CustomButtonData,
         action: @escaping () -> Void
    ) {
        self.data = data
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(data.title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
        }
        .glassEffect(.regular.tint(data.enabled ? Color.blue : Color.gray).interactive(),
                     in: Capsule())
        .disabled(data.enabled.not)
    }
}

#Preview {
    CustomButton(data: .init(title: "", enabled: false)) { }
}
