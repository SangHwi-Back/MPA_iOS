//
//  MainDateListSwipeableItem.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateListSwipeableItem: View {
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiped: Bool = false
    private let product: Product
    private let onDelete: (() -> Void)?
    let isPressed: Bool
    
    init(product: Product, isPressed: Bool = false, onDelete: (() -> Void)? = nil) {
        self.product = product
        self.isPressed = isPressed
        self.onDelete = onDelete
    }
    
    private var DeleteButton: some View {
        Button {
            onDelete?()
        } label: {
            ZStack {
                Rectangle().fill(Color.red)
                Image(systemName: "minus").foregroundStyle(.white)
            }
            .frame(width: 60).frame(maxHeight: .infinity)
        }
    }
    
    var body: some View {
        HStack {
            MainDateListLabel()
            
            if isSwiped {
                DeleteButton
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut, value: isSwiped)
        .offset(x: swipeOffset)
        .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onChanged { gesture in
                if gesture.translation.width < 0 {
                    swipeOffset = gesture.translation.width
                    if swipeOffset <= -60 {
                        isSwiped = true
                    }
                } else {
                    swipeOffset = isSwiped ? gesture.translation.width : 0
                }
            }
            .onEnded { gesture in
                if gesture.translation.width > 20 {
                    isSwiped = false
                }
                swipeOffset = 0
            }
        )
    }
}
