//
//  Button+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 8/3/25.
//

import SwiftUI

struct ButtonWithAnimate<Label: View>: View {
    let action: () -> Void
    let animation: Animation
    let label: () -> Label

    init(
        animation: Animation = .default,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.animation = animation
        self.label = label
    }

    var body: some View {
        Button(action: {
            withAnimation(animation) {
                action()
            }
        }, label: {
            Circle()
                .stroke(Color.white, lineWidth: 1, antialiased: true)
                .background(content: {
                    label().padding(4)
                })
                .glassEffect()
        })
    }
}
