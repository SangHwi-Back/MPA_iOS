//
//  Principle.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import Foundation
import SwiftUI

// MARK: - Category

enum PrincipleCategory: String, Codable, Hashable {
    case morning      = "아침"
    case evening      = "저녁"
    case allDay       = "아침/저녁"

    /// Label shown in the detail card, e.g. "아침 원칙".
    var label: String { rawValue + " 원칙" }
}

// MARK: - Model

struct Principle: Identifiable, Hashable {
    let id: UUID

    /// Display name, e.g. "경청", "꾸준함".
    var name: String

    /// 1 – 5 for current principles; `nil` for past.
    var rank: Int?

    /// Total number of journal entries that contain this keyword.
    var frequency: Int

    var firstSeenDate: Date
    var lastSeenDate: Date

    /// "‡" badge — a long-standing / core principle.
    var isCore: Bool

    /// "새" badge — appeared within the last 7 days.
    var isNew: Bool

    /// `true` → shown under "지금은 원칙"; `false` → "지난해 원칙".
    var isCurrent: Bool

    var category: PrincipleCategory

    /// AI-generated one-liner (nil when not yet generated).
    var principleDescription: AIText?

    /// 8 weekly counts, oldest → newest. `0` means no entry that week.
    var weeklyCounts: [Int]

    /// Journal IDs that surfaced this principle (most recent first).
    var relatedJournalIDs: [UUID]

    // Past-principle metadata (nil when `isCurrent`).
    /// Short label for the appearance window, e.g. "9월 1".
    var appearancePeriod: String?
    /// Duration in weeks the principle was tracked.
    var weekDuration: Int?

    init(
        id: UUID = UUID(),
        name: String,
        rank: Int? = nil,
        frequency: Int,
        firstSeenDate: Date,
        lastSeenDate: Date,
        isCore: Bool = false,
        isNew: Bool = false,
        isCurrent: Bool = true,
        category: PrincipleCategory = .morning,
        principleDescription: AIText? = nil,
        weeklyCounts: [Int] = [],
        relatedJournalIDs: [UUID] = [],
        appearancePeriod: String? = nil,
        weekDuration: Int? = nil
    ) {
        self.id            = id
        self.name          = name
        self.rank          = rank
        self.frequency     = frequency
        self.firstSeenDate = firstSeenDate
        self.lastSeenDate  = lastSeenDate
        self.isCore        = isCore
        self.isNew         = isNew
        self.isCurrent     = isCurrent
        self.category      = category
        self.principleDescription = principleDescription
        self.weeklyCounts   = weeklyCounts
        self.relatedJournalIDs = relatedJournalIDs
        self.appearancePeriod  = appearancePeriod
        self.weekDuration      = weekDuration
    }
}

// MARK: - Formatting helpers

extension Principle {

    /// Colour index into `principleScale` (0-based).
    var colorIndex: Int {
        (rank ?? 0) - 1
    }

    /// The 8 week-start labels for the bar chart, e.g. "9/7", "10/12".
    var weekLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        // Newest week-start is 6 weeks before `lastSeenDate`-ish; we just space
        // 8 Mondays evenly. In production this would come from the store.
        
        guard let lastWeekStart = calendar.date(byAdding: .weekday, value: 1, to: .now) else {
            return Array(0..<8).map { _ in "\(0)" }
        }
        return (0..<8).reversed().map { offset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -(7 - offset), to: lastWeekStart) ?? .now
            return formatter.string(from: weekStart)
        }
    }

    /// Sub-line under the name on a current list row: "7번 · 마지막 10월 27일".
    var currentRowSubtitle: String {
        let df = DateFormatter()
        df.dateFormat = "M월 d일"
        return "\(frequency)번 · 마지막 \(df.string(from: lastSeenDate))"
    }

    /// Sub-line for a past row: "9월 1 · 3주 동안 1회".
    var pastRowSubtitle: String {
        var parts: [String] = []
        if let period = appearancePeriod { parts.append(period) }
        if let weeks = weekDuration, weeks > 0 {
            parts.append("\(weeks)주 동안 \(frequency)회")
        }
        return parts.joined(separator: " · ")
    }

    /// Sub-title on the detail screen: "지금은 원칙 1순위 · 최신" / "지난해 원칙".
    var detailSubtitle: String {
        if isCurrent {
            var s = "지금은 원칙 \(rank ?? 0)순위"
            if isNew { s += " · 최신" }
            return s
        }
        return "지난해 원칙"
    }
}

// MARK: - Static helpers

extension Principle {
    /// Returns the recency-scale colour for this principle's rank.
    var bubbleColor: Color {
        let idx = min(max(colorIndex, 0), 4)
        let light = LightColorHex.principleScale[idx]
        let dark  = DarkColorHex.principleScale[idx]
        return Color.mpa(light, dark: dark)
    }
}

// MARK: - Sample data (design / preview)

extension Principle {

    static func sampleCurrent() -> [Principle] {
        let cal = Calendar(identifier: .gregorian)
        let d: (Int, Int, Int) -> Date = { y, m, day in
            cal.date(from: DateComponents(year: 2026, month: m, day: day)) ?? .now
        }

        let ai = AIText(
            text: "다른 사람의 말을 끝까지 듣고, 내 생각보다 더 질문을 먼저 꺼내는 태도예요.",
            engine: .appleIntelligence,
            generatedAt: d(2026, 10, 30),
            sourceJournalIDs: []
        )

        return [
            Principle(name: "경청", rank: 1, frequency: 7,
                      firstSeenDate: d(2026, 9, 14), lastSeenDate: d(2026, 10, 27),
                      isCurrent: true, category: .morning,
                      principleDescription: ai,
                      weeklyCounts: [0, 1, 2, 1, 0, 1, 1, 1],
                      relatedJournalIDs: []),
            Principle(name: "꾸준함", rank: 2, frequency: 5,
                      firstSeenDate: d(2026, 9, 1), lastSeenDate: d(2026, 10, 12),
                      isCore: true, isCurrent: true, category: .allDay,
                      weeklyCounts: [1, 1, 1, 1, 0, 1, 0, 0],
                      relatedJournalIDs: []),
            Principle(name: "솔직함", rank: 3, frequency: 4,
                      firstSeenDate: d(2026, 9, 1), lastSeenDate: d(2026, 10, 12),
                      isCurrent: true, category: .morning,
                      weeklyCounts: [1, 0, 0, 1, 1, 1, 0, 0],
                      relatedJournalIDs: []),
            Principle(name: "휴식", rank: 4, frequency: 3,
                      firstSeenDate: d(2026, 10, 12), lastSeenDate: d(2026, 10, 30),
                      isNew: true, isCurrent: true, category: .evening,
                      weeklyCounts: [0, 0, 0, 0, 0, 0, 1, 2],
                      relatedJournalIDs: []),
            Principle(name: "감사", rank: 5, frequency: 2,
                      firstSeenDate: d(2026, 10, 26), lastSeenDate: d(2026, 10, 26),
                      isCurrent: true, category: .evening,
                      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 2],
                      relatedJournalIDs: []),
        ]
    }

    static func samplePast() -> [Principle] {
        let cal = Calendar(identifier: .gregorian)
        let d: (Int, Int, Int) -> Date = { y, m, day in
            cal.date(from: DateComponents(year: 2026, month: m, day: day)) ?? .now
        }

        return [
            Principle(name: "인내", frequency: 1, firstSeenDate: d(2026, 9, 1), lastSeenDate: d(2026, 9, 22), isCurrent: false, appearancePeriod: "9월 1", weekDuration: 3),
            Principle(name: "운동", frequency: 2, firstSeenDate: d(2026, 8, 1), lastSeenDate: d(2026, 8, 15), isCurrent: false, appearancePeriod: "8월", weekDuration: 2)
        ]
    }

    static func sampleRelatedJournals() -> [Journal] {
        let cal = Calendar(identifier: .gregorian)
        let d: (Int, Int, Int) -> Date = { y, m, day in
            cal.date(from: DateComponents(year: 2026, month: m, day: day)) ?? .now
        }
        return [
            Journal(day: d(2026, 10, 27),
                    title: "회의에서 말을 끊지 않기",
                    body: "오늘 주간 회의에서 끝까지 들어 보기로 마음먹었다."),
            Journal(day: d(2026, 10, 20),
                    title: "엄마의 말 경청",
                    body: "엄마가 전화하실 때 끝까지 듣고 대답했다."),
            Journal(day: d(2026, 10, 12),
                    title: "팀 회의에서 먼저 묻기",
                    body: "리더 미팅에서 결론보다 질문을 먼저 꺼냈다."),
        ]
    }
}
