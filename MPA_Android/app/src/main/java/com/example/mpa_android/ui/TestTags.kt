// [NO AC]
package com.example.mpa_android.ui

import java.time.LocalDate

/** UI test tags. The strings must match iOS `AccessibilityID.swift` exactly. */
object TestTags {
    /** AI cards shared by several screens (`ai.card.<kind>`). */
    object AICard {
        const val HOME_ADVICE = "ai.card.homeAdvice"
        const val HOME_WEEKLY = "ai.card.homeWeekly"

        fun text(card: String) = "$card.text"
        fun sourceLabel(card: String) = "$card.sourceLabel"
        fun retry(card: String) = "$card.retry"
        fun checkKey(card: String) = "$card.checkKey"
        fun feedbackUp(card: String) = "$card.feedbackUp"
        fun feedbackDown(card: String) = "$card.feedbackDown"
        fun regenerate(card: String) = "$card.regenerate"
        fun moreAdvice(card: String) = "$card.moreAdvice"
        /** Source chip, numbered from 1 in display order. */
        fun source(card: String, index: Int) = "$card.source.$index"
    }

    object AI {
        const val HELP_CARD = "ai.helpCard"
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
}
