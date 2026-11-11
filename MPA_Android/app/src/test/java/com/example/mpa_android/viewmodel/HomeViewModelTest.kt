// [NO AC] Spec: specs/home/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import com.example.mpa_android.model.AIEngine
import com.example.mpa_android.model.AIUnavailableReason
import com.example.mpa_android.model.HomeAIStatus
import com.example.mpa_android.model.HomeLayout
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalKeyword
import com.example.mpa_android.model.KeywordSource
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.Locale
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

private val HOME_CREATED: Instant = Instant.parse("2026-10-27T12:40:00Z")
private val HOME_NOW: LocalDateTime = LocalDateTime.of(2026, 10, 30, 8, 0)

private fun homeJournal(day: LocalDate, keywords: List<Pair<String, Double>> = emptyList(), body: String = "") = Journal(
    day = day,
    createdAt = HOME_CREATED,
    body = body,
    keywords = keywords.map { JournalKeyword(it.first, KeywordSource.AI, it.second) },
)

private fun oct(day: Int): LocalDate = LocalDate.of(2026, 10, day)

class HomeViewModelTest {

    // ---- Layout and text ----

    @Test
    fun layoutFollowsStateMatrix() {
        assertEquals(HomeLayout.FIRST_RUN, HomeViewModel.layout(0, isAIAvailable = true))
        assertEquals(HomeLayout.FIRST_RUN, HomeViewModel.layout(0, isAIAvailable = false))
        assertEquals(HomeLayout.DIARY, HomeViewModel.layout(3, isAIAvailable = false))
        assertEquals(HomeLayout.EARLY, HomeViewModel.layout(2, isAIAvailable = true))
        assertEquals(HomeLayout.FULL, HomeViewModel.layout(3, isAIAvailable = true))
    }

    @Test
    fun greetingBoundaries() {
        assertEquals("반가워요", HomeViewModel.greeting(hour = 12, isFirstRun = true))
        assertEquals("편안한 밤이에요", HomeViewModel.greeting(hour = 4, isFirstRun = false))
        assertEquals("좋은 아침이에요", HomeViewModel.greeting(hour = 5, isFirstRun = false))
        assertEquals("좋은 아침이에요", HomeViewModel.greeting(hour = 11, isFirstRun = false))
        assertEquals("좋은 오후예요", HomeViewModel.greeting(hour = 12, isFirstRun = false))
        assertEquals("좋은 오후예요", HomeViewModel.greeting(hour = 17, isFirstRun = false))
        assertEquals("좋은 저녁이에요", HomeViewModel.greeting(hour = 18, isFirstRun = false))
        assertEquals("좋은 저녁이에요", HomeViewModel.greeting(hour = 21, isFirstRun = false))
        assertEquals("편안한 밤이에요", HomeViewModel.greeting(hour = 22, isFirstRun = false))
    }

    @Test
    fun dateTexts() {
        assertEquals("10월 30일 금요일", HomeViewModel.dateLine(oct(30), Locale.KOREAN))
        assertEquals("10월 26일–30일", HomeViewModel.rangeText(oct(26), oct(30)))
        assertEquals("10월 30일–11월 1일", HomeViewModel.rangeText(oct(30), LocalDate.of(2026, 11, 1)))
        assertEquals("10월 30일", HomeViewModel.rangeText(oct(30), oct(30)))
    }

    // ---- Week strip ----

    @Test
    fun weekDaysRunMondayToSunday() {
        val days = HomeViewModel.weekDays(today = oct(30), offset = 0, entries = listOf(homeJournal(oct(27))))

        assertEquals(7, days.size)
        assertEquals(oct(26), days[0].date)
        assertTrue(days[4].isToday)
        assertTrue(days[5].isFuture && days[6].isFuture)
        assertFalse(days[3].isFuture)
        assertTrue(days[1].hasEntry)
        assertFalse(days[2].hasEntry)
    }

    @Test
    fun weekDaysOffsetGoesBackAWeek() {
        val days = HomeViewModel.weekDays(today = oct(30), offset = -1, entries = emptyList())

        assertEquals(oct(19), days[0].date)
        assertTrue(days.none { it.isToday || it.isFuture })
    }

    // ---- Principles ----

    @Test
    fun principlesRankByEntryCountAndStageByRecency() {
        val entries = listOf(
            homeJournal(oct(20), listOf("경청" to 0.2)),
            homeJournal(oct(27), listOf("경청" to 0.8)),
            homeJournal(oct(29), listOf("휴식" to 0.9)),
        )

        val principles = HomeViewModel.principles(entries)

        assertEquals(listOf("경청", "휴식"), principles.map { it.name })
        assertEquals(2, principles[0].count)
        assertEquals(1, principles[0].stage)
        assertEquals(0, principles[1].stage)
    }

    @Test
    fun relatedEntriesAreTopThreeByInfluence() {
        val entries = (1..4).map { index -> homeJournal(oct(20 + index), listOf("경청" to index.toDouble())) }

        val related = HomeViewModel.principles(entries).single().related

        assertEquals(listOf(oct(24), oct(23), oct(22)), related.map { it.day })
    }

    @Test
    fun bubbleDiameterKeepsMinimum() {
        assertEquals(64f, HomeViewModel.bubbleDiameter(count = 1, maxCount = 100), 0.01f)
        assertEquals(124f, HomeViewModel.bubbleDiameter(count = 10, maxCount = 10), 0.01f)
    }

    // ---- HomeUiState ----

    @Test
    fun todayEntryMatchesNow() {
        val state = HomeUiState(entries = listOf(homeJournal(oct(30)), homeJournal(oct(29))), now = HOME_NOW)

        assertEquals(oct(30), state.todayEntry?.day)
        assertEquals(null, HomeUiState(entries = listOf(homeJournal(oct(29))), now = HOME_NOW).todayEntry)
    }

    @Test
    fun weeklySummaryNeedsThreeEntriesThisWeekAndAI() {
        val three = listOf(homeJournal(oct(12)), homeJournal(oct(20)), homeJournal(oct(30)))
        val available = HomeAIStatus.Available(AIEngine.GEMINI_NANO)

        assertFalse(HomeUiState(entries = three.take(2), aiStatus = available, now = HOME_NOW).showsWeeklySummary)
        assertTrue(HomeUiState(entries = three, aiStatus = available, now = HOME_NOW).showsWeeklySummary)
        assertFalse(
            HomeUiState(
                entries = three,
                aiStatus = HomeAIStatus.Unavailable(AIUnavailableReason.TURNED_OFF),
                now = HOME_NOW,
            ).showsWeeklySummary,
        )
        // Nothing this week (Oct 26–Nov 1).
        assertFalse(HomeUiState(entries = three.take(2) + homeJournal(oct(5)), aiStatus = available, now = HOME_NOW).showsWeeklySummary)
    }

    @Test
    fun weeklyRangeLineCountsThisWeek() {
        val state = HomeUiState(entries = listOf(homeJournal(oct(26)), homeJournal(oct(30)), homeJournal(oct(20))), now = HOME_NOW)

        assertEquals("10월 26일–30일 · 일기 2개", state.weeklyRangeLine)
    }

    @Test
    fun sensitiveContentInRecentEntries() {
        assertTrue(HomeUiState(entries = listOf(homeJournal(oct(27), body = "요즘 죽고 싶다")), now = HOME_NOW).isSensitive)
        assertFalse(HomeUiState(entries = listOf(homeJournal(oct(27), body = "산책을 했다")), now = HOME_NOW).isSensitive)
    }
}
