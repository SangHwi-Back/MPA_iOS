//
//  MainDateListItem.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateListItem: View {
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiped: Bool = false
    private let product: Product
    
    init(product: Product) {
        self.product = product
    }
    
    var body: some View {
        HStack {
            MainDateListLabel()
            
            if isSwiped {
                Button {
                    print("Delete!")
                } label: {
                    ZStack {
                        Rectangle()
                            .fill(Color.red)
                        
                        Image(systemName: "minus")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 60)
                    .frame(maxHeight: .infinity)
                }
            }
        }
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
