//
//  [NO AC]
//
//  AccessibilityID.swift
//  MPA_ios
//
//  UI test identifiers. The strings must match Android `TestTags.kt` exactly.
//

import Foundation

enum AccessibilityID {
    /// AI cards shared by several screens (`ai.card.<kind>`).
    enum AICard {
        static let homeAdvice = "ai.card.homeAdvice"
        static let homeWeekly = "ai.card.homeWeekly"

        static func text(_ card: String) -> String { "\(card).text" }
        static func sourceLabel(_ card: String) -> String { "\(card).sourceLabel" }
        static func retry(_ card: String) -> String { "\(card).retry" }
        static func checkKey(_ card: String) -> String { "\(card).checkKey" }
        static func feedbackUp(_ card: String) -> String { "\(card).feedbackUp" }
        static func feedbackDown(_ card: String) -> String { "\(card).feedbackDown" }
        static func regenerate(_ card: String) -> String { "\(card).regenerate" }
        static func moreAdvice(_ card: String) -> String { "\(card).moreAdvice" }
        /// Source chip, numbered from 1 in display order.
        static func source(_ card: String, _ index: Int) -> String { "\(card).source.\(index)" }
    }

    enum AI {
        static let helpCard = "ai.helpCard"
    }

    enum Home {
        static let screen = "home.screen"
        static let greeting = "home.greeting"
        static let date = "home.date"
        static let newJournalButton = "home.newJournalButton"
        static let aiWarningButton = "home.aiWarningButton"

        static let prompt = "home.prompt"
        static let promptText = "home.prompt.text"
        static let promptWrite = "home.prompt.write"
        static let promptAnother = "home.prompt.another"

        static let todayPreview = "home.todayPreview"

        static let principles = "home.principles"
        static let principlesHeader = "home.principles.header"
        static let principlesSeeAll = "home.principles.seeAll"
        static let principlesLegend = "home.principles.legend"
        static let principlesProgress = "home.principles.progress"
        static func principlesBubble(_ name: String) -> String { "home.principles.bubble.\(name)" }

        static let weeklySummaryLine = "home.weekly.summaryLine"

        static let empty = "home.empty"
        static func emptyExample(_ index: Int) -> String { "home.empty.example.\(index)" }
        static let privacyNote = "home.privacyNote"

        static let todayCard = "home.todayCard"
        static let todayCardWrite = "home.todayCard.write"

        static let weekStrip = "home.weekStrip"
        static let weekStripCalendar = "home.weekStrip.calendar"
        static func weekStripDay(_ date: Date) -> String { "home.weekStrip.day.\(AccessibilityID.dayKey(date))" }

        static let recent = "home.recent"
        static let recentSeeAll = "home.recent.seeAll"
        static func recentItem(_ index: Int) -> String { "home.recent.item.\(index)" }

        // iPad drawer
        static let drawer = "home.drawer"
        static let drawerCalendarToggle = "home.drawer.calendarToggle"
        static let drawerSeeAll = "home.drawer.seeAll"
        static func drawerItem(_ index: Int) -> String { "home.drawer.item.\(index)" }
        static let drawerCalendarMonth = "home.drawer.calendar.month"
        static let drawerCalendarPrev = "home.drawer.calendar.prev"
        static let drawerCalendarNext = "home.drawer.calendar.next"
        static func drawerCalendarDay(_ date: Date) -> String { "home.drawer.calendar.day.\(AccessibilityID.dayKey(date))" }
        static let drawerCalendarSelectedHeader = "home.drawer.calendar.selectedHeader"
        static func drawerCalendarEntry(_ index: Int) -> String { "home.drawer.calendar.entry.\(index)" }
    }

    /// `yyyy-MM-dd` in the current calendar, independent of the user's locale.
    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
