//
//  JournalEmptyViews.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

struct JournalMonthEmptyView: View {
    var body: some View {
        Text("이 달의 기록이 없어요")
            .font(.system(size: 15))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

struct JournalEmptyStateView: View {
    let onWriteFirst: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image("empty_journal")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 130)
                .accessibilityHidden(true)

            Text("아직 기록이 없어요")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 12)

            Text("첫 일기를 쓰면 여기에\n날짜별로 차곡차곡 모여요.")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Button(action: onWriteFirst) {
                HStack(spacing: 8) {
                    Image("edit")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("첫 일기 쓰기")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color.BRAND_ON_PRIMARY)
                .padding(.horizontal, 26)
                .frame(height: 48)
                .background(Capsule().fill(Color.BRAND_PRIMARY))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

struct JournalDayEmptyView: View {
    let onWrite: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("이 날의 기록이 없어요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Button("이 날짜로 쓰기", action: onWrite)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .buttonStyle(.plain)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
