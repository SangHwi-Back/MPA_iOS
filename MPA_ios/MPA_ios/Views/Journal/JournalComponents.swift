//
//  JournalComponents.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

enum JournalDateText {
    static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    static func day(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    static func weekday(_ date: Date) -> String {
        weekdays[Calendar.current.component(.weekday, from: date) - 1]
    }

    static func month(_ date: Date) -> String {
        "\(Calendar.current.component(.month, from: date))월"
    }

    static func yearMonth(_ date: Date) -> String {
        "\(Calendar.current.component(.year, from: date))년 \(month(date))"
    }

    static func selectedDay(_ date: Date) -> String {
        "\(month(date)) \(day(date))일 \(weekday(date))요일"
    }
}

struct JournalKeywordChip: View {
    let name: String
    let stage: Int
    var isEmphasized: Bool = false
    var textColor: Color = .AI_ACCENT

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.PRINCIPLE_SCALES[min(stage, Color.PRINCIPLE_SCALES.count - 1)])
                .frame(width: 7, height: 7)
            Text(name)
                .font(.system(size: 13, weight: isEmphasized ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Capsule().fill(Color.AI_TINT))
    }
}
