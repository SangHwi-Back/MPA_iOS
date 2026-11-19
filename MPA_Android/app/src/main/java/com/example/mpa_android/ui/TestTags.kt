// [NO AC]
package com.example.mpa_android.ui

import java.time.LocalDate

/** UI test tags. The strings must match iOS `AccessibilityID.swift` exactly. */
object TestTags {
    /** AI cards shared by several screens (`ai.card.<kind>`). */
    object AICard {
        const val HOME_ADVICE = "ai.card.homeAdvice"
        const val HOME_WEEKLY = "ai.card.homeWeekly"
        const val JOURNAL_COMMENT = "ai.card.journalComment"

        fun text(card: String) = "$card.text"
        fun sourceLabel(card: String) = "$card.sourceLabel"
        fun retry(card: String) = "$card.retry"
        fun checkKey(card: String) = "$card.checkKey"
        fun feedbackUp(card: String) = "$card.feedbackUp"
        fun feedbackDown(card: String) = "$card.feedbackDown"
        fun regenerate(card: String) = "$card.regenerate"
        fun moreAdvice(card: String) = "$card.moreAdvice"
        /** Header that expands or collapses a card. */
        fun toggle(card: String) = "$card.toggle"
        /** Source chip, numbered from 1 in display order. */
        fun source(card: String, index: Int) = "$card.source.$index"
    }

    object AI {
        const val HELP_CARD = "ai.helpCard"
        const val HELP_CARD_CALL = "ai.helpCard.call"
        const val HELP_CARD_RESOURCES = "ai.helpCard.resources"
    }

    object Home {
        const val SCREEN = "home.screen"
        const val GREETING = "home.greeting"
        const val DATE = "home.date"
        const val NEW_JOURNAL_BUTTON = "home.newJournalButton"
        const val AI_WARNING_BUTTON = "home.aiWarningButton"

        const val PROMPT = "home.prompt"
        const val PROMPT_TEXT = "home.prompt.text"
        const val PROMPT_WRITE = "home.prompt.write"
        const val PROMPT_ANOTHER = "home.prompt.another"

        const val TODAY_PREVIEW = "home.todayPreview"

        const val PRINCIPLES = "home.principles"
        const val PRINCIPLES_SEE_ALL = "home.principles.seeAll"
        const val PRINCIPLES_LEGEND = "home.principles.legend"
        const val PRINCIPLES_PROGRESS = "home.principles.progress"
        fun principlesBubble(name: String) = "home.principles.bubble.$name"

        const val WEEKLY_SUMMARY_LINE = "home.weekly.summaryLine"

        const val EMPTY = "home.empty"
        fun emptyExample(index: Int) = "home.empty.example.$index"
        const val PRIVACY_NOTE = "home.privacyNote"

        const val TODAY_CARD = "home.todayCard"
        const val TODAY_CARD_WRITE = "home.todayCard.write"

        const val WEEK_STRIP = "home.weekStrip"
        const val WEEK_STRIP_CALENDAR = "home.weekStrip.calendar"
        fun weekStripDay(date: LocalDate) = "home.weekStrip.day.$date"

        const val RECENT = "home.recent"
        const val RECENT_SEE_ALL = "home.recent.seeAll"
        fun recentItem(index: Int) = "home.recent.item.$index"

        // iPad drawer (iOS only; kept so both files list the same names)
        const val DRAWER = "home.drawer"
        const val DRAWER_CALENDAR_TOGGLE = "home.drawer.calendarToggle"
        const val DRAWER_SEE_ALL = "home.drawer.seeAll"
        fun drawerItem(index: Int) = "home.drawer.item.$index"
        const val DRAWER_CALENDAR_MONTH = "home.drawer.calendar.month"
        const val DRAWER_CALENDAR_PREV = "home.drawer.calendar.prev"
        const val DRAWER_CALENDAR_NEXT = "home.drawer.calendar.next"
        fun drawerCalendarDay(date: LocalDate) = "home.drawer.calendar.day.$date"
        const val DRAWER_CALENDAR_SELECTED_HEADER = "home.drawer.calendar.selectedHeader"
        fun drawerCalendarEntry(index: Int) = "home.drawer.calendar.entry.$index"
    }

    // Journal › 일기 상세
    object Detail {
        const val SCREEN = "detail.screen"
        const val BACK = "detail.back"
        const val EDIT = "detail.edit"
        const val MORE = "detail.more"
        const val MENU_SHARE = "detail.menu.share"
        const val MENU_CHANGE_DAY = "detail.menu.changeDay"
        const val MENU_DELETE = "detail.menu.delete"
        const val KEYWORDS = "detail.keywords"
        const val KEYWORDS_LOADING = "detail.keywords.loading"
        fun keyword(index: Int) = "detail.keyword.$index"
        const val DATE = "detail.date"
        const val TITLE = "detail.title"
        const val BODY = "detail.body"
        const val PHOTOS = "detail.photos"
        fun photo(index: Int) = "detail.photo.$index"
        const val EDITED_AT = "detail.editedAt"
        const val KEYWORD_SHEET = "detail.keywordSheet"
        const val KEYWORD_SHEET_TITLE = "detail.keywordSheet.title"
        const val KEYWORD_SHEET_SUMMARY = "detail.keywordSheet.summary"
        const val KEYWORD_SHEET_PRINCIPLE = "detail.keywordSheet.principle"
        const val KEYWORD_SHEET_OUT_OF_RANK = "detail.keywordSheet.outOfRank"
        const val KEYWORD_SHEET_CLOSE = "detail.keywordSheet.close"
        fun keywordSheetItem(index: Int) = "detail.keywordSheet.item.$index"
        const val DATE_PICKER = "detail.datePicker"
        const val DATE_PICKER_CALENDAR = "detail.datePicker.calendar"
        const val DATE_PICKER_CANCEL = "detail.datePicker.cancel"
        const val DATE_PICKER_CONFIRM = "detail.datePicker.confirm"
    }

    // Journal › 에디터
    object Editor {
        const val SCREEN = "editor.screen"
        const val CLOSE = "editor.close"
        const val DONE = "editor.done"
        const val DATE = "editor.date"
        const val PROMPT = "editor.prompt"
        const val PROMPT_REMOVE = "editor.prompt.remove"
        const val TITLE = "editor.title"
        const val BODY = "editor.body"
        const val KEYWORDS = "editor.keywords"
        fun keyword(index: Int) = "editor.keyword.$index"
        const val TOOLBAR = "editor.toolbar"
        const val TOOLBAR_PHOTO = "editor.toolbar.photo"
        const val TOOLBAR_MIC = "editor.toolbar.mic"
        const val DATE_PICKER = "editor.datePicker"
        const val DATE_PICKER_CALENDAR = "editor.datePicker.calendar"
        const val DATE_PICKER_CANCEL = "editor.datePicker.cancel"
        const val DATE_PICKER_CONFIRM = "editor.datePicker.confirm"
    }

    // Settings › 데이터는 어디에 저장되나요?
    object InformationPrivacyDescription {
        const val SCREEN = "informationPrivacyDescription.screen"
        const val BACK = "informationPrivacyDescription.back"
        const val TITLE = "informationPrivacyDescription.title"
        const val STORAGE = "informationPrivacyDescription.storage"
        const val READERS = "informationPrivacyDescription.readers"
        const val DELETION = "informationPrivacyDescription.deletion"
        /** [key]: "onDevice", "gemini", "openAI". */
        fun reader(key: String) = "informationPrivacyDescription.reader.$key"
        fun readerInUse(key: String) = "informationPrivacyDescription.reader.$key.inUse"
    }

    // Settings › 매일 쓰기 알림
    object AlertDailyWriteDatePicker {
        const val SCREEN = "alertDailyWriteDatePicker.screen"
        const val CANCEL = "alertDailyWriteDatePicker.cancel"
        const val CONFIRM = "alertDailyWriteDatePicker.confirm"
        const val TOGGLE = "alertDailyWriteDatePicker.toggle"
        const val TIME_PICKER = "alertDailyWriteDatePicker.timePicker"
        const val INPUT_MODE_TOGGLE = "alertDailyWriteDatePicker.inputModeToggle"
    }

    // Settings › 기록 내보내기
    object AlertExportJournals {
        const val SCREEN = "alertExportJournals.screen"
        const val MESSAGE = "alertExportJournals.message"
        const val OPTION_MARKDOWN = "alertExportJournals.option.markdown"
        const val OPTION_JSON = "alertExportJournals.option.json"
        const val CONFIRM = "alertExportJournals.confirm"
        const val CANCEL = "alertExportJournals.cancel"
    }
}
