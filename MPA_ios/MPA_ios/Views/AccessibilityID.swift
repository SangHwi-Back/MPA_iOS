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
        static let journalComment = "ai.card.journalComment"

        static func text(_ card: String) -> String { "\(card).text" }
        static func sourceLabel(_ card: String) -> String { "\(card).sourceLabel" }
        static func retry(_ card: String) -> String { "\(card).retry" }
        static func checkKey(_ card: String) -> String { "\(card).checkKey" }
        static func feedbackUp(_ card: String) -> String { "\(card).feedbackUp" }
        static func feedbackDown(_ card: String) -> String { "\(card).feedbackDown" }
        static func regenerate(_ card: String) -> String { "\(card).regenerate" }
        static func moreAdvice(_ card: String) -> String { "\(card).moreAdvice" }
        /// Header that expands or collapses a card.
        static func toggle(_ card: String) -> String { "\(card).toggle" }
        /// Source chip, numbered from 1 in display order.
        static func source(_ card: String, _ index: Int) -> String { "\(card).source.\(index)" }
    }

    enum AI {
        static let helpCard = "ai.helpCard"
        static let helpCardCall = "ai.helpCard.call"
        static let helpCardResources = "ai.helpCard.resources"
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

    // Journal › 일기 상세
    enum Detail {
        static let screen = "detail.screen"
        static let back = "detail.back"
        static let edit = "detail.edit"
        static let more = "detail.more"
        static let menuShare = "detail.menu.share"
        static let menuChangeDay = "detail.menu.changeDay"
        static let menuDelete = "detail.menu.delete"
        static let keywords = "detail.keywords"
        static let keywordsLoading = "detail.keywords.loading"
        static func keyword(_ index: Int) -> String { "detail.keyword.\(index)" }
        static let date = "detail.date"
        static let title = "detail.title"
        static let body = "detail.body"
        static let photos = "detail.photos"
        static func photo(_ index: Int) -> String { "detail.photo.\(index)" }
        static let editedAt = "detail.editedAt"
        static let keywordSheet = "detail.keywordSheet"
        static let keywordSheetTitle = "detail.keywordSheet.title"
        static let keywordSheetSummary = "detail.keywordSheet.summary"
        static let keywordSheetPrinciple = "detail.keywordSheet.principle"
        static let keywordSheetOutOfRank = "detail.keywordSheet.outOfRank"
        static let keywordSheetClose = "detail.keywordSheet.close"
        static func keywordSheetItem(_ index: Int) -> String { "detail.keywordSheet.item.\(index)" }
        static let datePicker = "detail.datePicker"
        static let datePickerCalendar = "detail.datePicker.calendar"
        static let datePickerCancel = "detail.datePicker.cancel"
        static let datePickerConfirm = "detail.datePicker.confirm"
    }

    // Journal › 에디터
    enum Editor {
        static let screen = "editor.screen"
        static let close = "editor.close"
        static let done = "editor.done"
        static let date = "editor.date"
        static let prompt = "editor.prompt"
        static let promptRemove = "editor.prompt.remove"
        static let title = "editor.title"
        static let body = "editor.body"
        static let keywords = "editor.keywords"
        static func keyword(_ index: Int) -> String { "editor.keyword.\(index)" }
        static let toolbar = "editor.toolbar"
        static let toolbarPhoto = "editor.toolbar.photo"
        static let toolbarMic = "editor.toolbar.mic"
        static let datePicker = "editor.datePicker"
        static let datePickerCalendar = "editor.datePicker.calendar"
        static let datePickerCancel = "editor.datePicker.cancel"
        static let datePickerConfirm = "editor.datePicker.confirm"
    }

    // Settings › 데이터는 어디에 저장되나요?
    enum InformationPrivacyDescription {
        static let screen = "informationPrivacyDescription.screen"
        static let back = "informationPrivacyDescription.back"
        static let title = "informationPrivacyDescription.title"
        static let storage = "informationPrivacyDescription.storage"
        static let readers = "informationPrivacyDescription.readers"
        static let deletion = "informationPrivacyDescription.deletion"
        /// `key`: "onDevice", "gemini", "openAI".
        static func reader(_ key: String) -> String { "informationPrivacyDescription.reader.\(key)" }
        static func readerInUse(_ key: String) -> String { "informationPrivacyDescription.reader.\(key).inUse" }
    }

    // Settings › 매일 쓰기 알림
    enum AlertDailyWriteDatePicker {
        static let screen = "alertDailyWriteDatePicker.screen"
        static let cancel = "alertDailyWriteDatePicker.cancel"
        static let confirm = "alertDailyWriteDatePicker.confirm"
        static let toggle = "alertDailyWriteDatePicker.toggle"
        static let timePicker = "alertDailyWriteDatePicker.timePicker"
        static let inputModeToggle = "alertDailyWriteDatePicker.inputModeToggle"
    }

    // Settings › 기록 내보내기
    enum AlertExportJournals {
        static let screen = "alertExportJournals.screen"
        static let message = "alertExportJournals.message"
        static let optionMarkdown = "alertExportJournals.option.markdown"
        static let optionJSON = "alertExportJournals.option.json"
        static let confirm = "alertExportJournals.confirm"
        static let cancel = "alertExportJournals.cancel"
    }

    /// `yyyy-MM-dd` in the current calendar, independent of the user's locale.
    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
