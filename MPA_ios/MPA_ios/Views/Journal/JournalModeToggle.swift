//
//  JournalModeToggle.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/26.
//

import SwiftUI

struct JournalModeToggle: View {
    @Binding var mode: JournalViewMode
    let height: CGFloat

    @Namespace private var selection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JournalViewMode.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = option }
                } label: {
                    Text(option.title)
                        .font(.system(size: 15, weight: mode == option ? .bold : .regular))
                        .foregroundStyle(mode == option ? Color.TEXT_PRIMARY : Color.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if mode == option {
                                Capsule()
                                    .fill(Color.SURFACE)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "selection", in: selection)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == option ? .isSelected : [])
            }
        }
        .padding(2)
        .frame(height: height)
        .background(Capsule().fill(Color.SUNKEN))
    }
}
