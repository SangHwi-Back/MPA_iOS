//
//  CommonModal.swift
//  MPA_ios
//
//  Created by 백상휘 on 2/16/26.
//

import SwiftUI

struct CommonModalModel: Equatable {
    static func == (lhs: CommonModalModel, rhs: CommonModalModel) -> Bool {
        return lhs.title == rhs.title
        && lhs.message == rhs.message
    }
    
    let title: String
    let message: String
    let onConfirm: (() -> Void)?
    let onCancel: (() -> Void)?
}

struct CommonModalContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let model: CommonModalModel
    let onDismiss: () -> Void
    
    /// onConfirm, onCancel 둘 다 nil인 경우 단일 Confirm 버튼 표시
    private var isBothNil: Bool {
        model.onConfirm == nil && model.onCancel == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title & Message
            VStack(spacing: 8) {
                Text(model.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(model.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            
            Divider()
            
            // Buttons
            if isBothNil {
                // 단일 버튼: 하단 양쪽 모두 rounded
                Button {
                    onDismiss()
                } label: {
                    Text("확인")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .glassEffect(
                    .regular.interactive(),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 0
                    )
                )
            } else {
                HStack(spacing: 0) {
                    if let onCancel = model.onCancel {
                        // 왼쪽 버튼: 왼쪽 하단만 rounded
                        Button {
                            onCancel()
                            onDismiss()
                        } label: {
                            Text("취소")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .glassEffect(
                            .regular.interactive(),
                            in: UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )
                        
                        Divider()
                            .frame(height: 44)
                    }
                    
                    if let onConfirm = model.onConfirm {
                        // 오른쪽 버튼: 오른쪽 하단만 rounded
                        // onCancel 없이 단독이면 하단 양쪽 rounded
                        Button {
                            onConfirm()
                            onDismiss()
                        } label: {
                            Text("확인")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .glassEffect(
                            .regular.interactive(),
                            in: UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: model.onCancel == nil ? 16 : 0,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 0
                            )
                        )
                    }
                }
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 40)
    }
}

extension ContentView {
    func CommonModalView(_ model: CommonModalModel, onDismiss: @escaping () -> Void) -> some View {
        CommonModalContentView(model: model, onDismiss: onDismiss)
    }
}

#Preview("취소 + 확인") {
    CommonModalContentView(
        model: CommonModalModel(
            title: "항목을 삭제할까요?",
            message: "삭제한 항목은 복구할 수 없습니다.",
            onConfirm: { print("확인") },
            onCancel: { print("취소") }
        ),
        onDismiss: { print("dismiss") }
    )
}

#Preview("확인만") {
    CommonModalContentView(
        model: CommonModalModel(
            title: "저장되었습니다",
            message: "변경 사항이 성공적으로 저장되었습니다.",
            onConfirm: { print("확인") },
            onCancel: nil
        ),
        onDismiss: { print("dismiss") }
    )
}

#Preview("버튼 없음 (자동 닫기)") {
    CommonModalContentView(
        model: CommonModalModel(
            title: "알림",
            message: "새로운 업데이트가 있습니다.",
            onConfirm: nil,
            onCancel: nil
        ),
        onDismiss: { print("dismiss") }
    )
}

