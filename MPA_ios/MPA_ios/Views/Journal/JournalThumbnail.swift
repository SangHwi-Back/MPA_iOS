//
//  JournalThumbnail.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

struct JournalThumbnail: View {
    let photo: JournalPhoto
    let extraCount: Int
    let size: CGFloat
    let showsGlyph: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.PLACEHOLDER)
            .overlay {
                if showsGlyph {
                    Image("image_placeholder_glyph")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if extraCount > 0 {
                    Text("+\(extraCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.black.opacity(0.55)))
                        .padding(4)
                }
            }
            .frame(width: size, height: size)
    }
}
