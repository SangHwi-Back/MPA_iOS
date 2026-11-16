//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  HomeFirstRunSection.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/15/26.
//

/**
 @uitest
 위에서 부터 3개의 `Text`가 있다. 3개의 `Text`는 각각 다음과 같다.
 1. 첫 일기를 써보세요
 2. 몇 줄이면 충분해요. 일기가 쌓이면\n그 안에서 나만의 원칙을 찾아드릴게요.
 3. 이런 질문으로 시작해 보세요.
 아래에는 `home.empty.example.` 로 시작하는 identifier 를 가진 버튼 3개가 존재한다. 해당 identifier 뒤에는 번호를 뜻하는 숫자가 1, 2, 3 차례로 부여된다.
 */

import SwiftUI

struct HomeFirstRunSection: View {
    /// nil hides the line (no AI: the warning button explains instead).
    let privacyLine: String?
    let onQuestion: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HomeEmptyIllustration()
                    .frame(height: 230)
                Text("첫 일기를 써보세요")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .padding(.top, 8)
                Text("몇 줄이면 충분해요. 일기가 쌓이면\n그 안에서 나만의 원칙을 찾아드릴게요.")
                    .font(.system(size: 16))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("이런 질문으로 시작해 보세요")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .padding(.bottom, 4)
                    ForEach(Array(HomeSamples.exampleQuestions.enumerated()), id: \.element) { index, question in
                        Button { onQuestion(question) } label: {
                            HStack {
                                Text(question)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.TEXT_PRIMARY)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.TEXT_TERTIARY)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(Color.SURFACE, in: .rect(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.Home.emptyExample(index + 1))
                    }
                }
                .padding(.top, 32)
                
                if let privacyLine {
                    Label(privacyLine, systemImage: "lock")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .padding(.top, 20)
                        .accessibilityIdentifier(AccessibilityID.Home.privacyNote)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Home.empty)
    }
}

// MARK: - HomeEmptyIllustration

struct HomeEmptyIllustration: View {
    var body: some View {
        ZStack {
            Image(systemName: "book")
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Image(systemName: "pencil")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .offset(x: 84, y: -10)
            Circle().stroke(Color.PRINCIPLE5, lineWidth: 2).frame(width: 14, height: 14).offset(x: 22, y: -98)
            Circle().stroke(Color.PRINCIPLE1, lineWidth: 2).frame(width: 34, height: 34).offset(x: 54, y: -84)
            Circle().stroke(Color.PRINCIPLE3, lineWidth: 2).frame(width: 18, height: 18).offset(x: 94, y: -94)
        }
        .accessibilityHidden(true)
    }
}
