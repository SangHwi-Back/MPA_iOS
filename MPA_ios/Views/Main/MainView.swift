//
//  MainView.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/4/25.
//

import SwiftUI
import FoundationModels

struct MainView: View {
    @Environment(\.showModal) var modalState: ModalState
    @State var replay: Bool = true
    @State var mainViewHeight: CGFloat = 280
    
    private var model = SystemLanguageModel.default
    
    var body: some View {
        ScrollView {
            AppleIntelligenceStatusView()
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            BubbleView(height: mainViewHeight)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .navigationTitle("Contents")
    }
}

// MARK: - Preview Helpers

/// Preview에서 ModalState를 주입하고 modal 오버레이까지 함께 테스트하기 위한 래퍼
private struct MainViewPreviewContainer<TopButton: View>: View {
    @State private var modalState = ModalState()
    let topButton: (ModalState) -> TopButton
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    topButton(modalState)
                        .padding(.horizontal)
                    MainView()
                }
            }
            .environment(\.showModal, modalState)
            
            if modalState.modalType != .none {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { modalState.modalType = .none }
                    .overlay {
                        if case .common(let model) = modalState.modalType {
                            CommonModalContentView(model: model) {
                                modalState.modalType = .none
                            }
                        }
                    }
            }
        }
    }
}

#Preview("취소 + 확인 버튼") {
    MainViewPreviewContainer { state in
        Button("Show Modal both closures") {
            state.modalType = .common(.init(
                title: "Title",
                message: "Messageeeeee",
                onConfirm: { print("ONCONFIRM") },
                onCancel: { print("ONCANCEL") }
            ))
        }
    }
}

#Preview("취소만") {
    MainViewPreviewContainer { state in
        Button("Show Modal cancel closures") {
            state.modalType = .common(.init(
                title: "Title",
                message: "Messageeeeee",
                onConfirm: nil,
                onCancel: { print("ONCANCEL") }
            ))
        }
    }
}

#Preview("확인만") {
    MainViewPreviewContainer { state in
        Button("Show Modal confirm closures") {
            state.modalType = .common(.init(
                title: "Title",
                message: "Messageeeeee",
                onConfirm: { print("ONCONFIRM") },
                onCancel: nil
            ))
        }
    }
}

#Preview("버튼 없음") {
    MainViewPreviewContainer { state in
        Button("Show Modal no closures") {
            state.modalType = .common(.init(
                title: "Title",
                message: "Messageeeeee",
                onConfirm: nil,
                onCancel: nil
            ))
        }
    }
}
