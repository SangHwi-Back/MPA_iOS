//
//  JournalSearchField.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/26.
//

import SwiftUI

struct JournalSearchField: View {
    @Bindable var viewModel: JournalViewModel
    
    let isEnabled: Bool
    var height: CGFloat = 40
    var cornerRadius: CGFloat = 12
    var onCancel: () -> Void = {}
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)

                TextField("제목, 본문, 키워드 검색", text: $viewModel.searchQuery)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.TEXT_TERTIARY)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("지우기")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Color.SUNKEN))
            .overlay {
                if viewModel.isSearchActive {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                }
            }
            .opacity(isEnabled ? 1 : 0.6)
            .disabled(!isEnabled)
            .onChange(of: isFocused) { _, focused in
                if focused {
                    viewModel.isSearchActive = true
                }
            }

            if viewModel.isSearchActive {
                Button("취소") {
                    isFocused = false
                    onCancel()
                }
                .font(.system(size: 16))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .buttonStyle(.plain)
            }
        }
    }
}
