@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.model

import java.time.LocalDate
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

/** Design example data for the 기록 previews. */
object JournalSamples {
    val list: List<Journal> = listOf(
        entry(30, "비 오기 전 산책", "하늘이 낮게 깔려서 우산을 챙겼는데 결국 비는 오지 않았다. 덕분에 천천히 걸었다.", listOf("휴식", "꾸준함"), hasPhoto = true),
        entry(29, "퇴근길 산책", "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.", listOf("꾸준함"), hasPhoto = true),
        entry(27, "회의에서 말을 끊지 않기", "끝까지 듣고 나니 내가 하려던 질문이 달라졌다. 다음 회의에도 먼저 묻고 말해야겠다.", listOf("경청", "솔직함"), hasPhoto = false),
        entry(26, "월요일의 작은 감사", "출근길에 커피를 건네준 동료에게 고맙다고 제대로 말했다.", listOf("감사"), hasPhoto = false),
        entry(22, "일찍 잠들기", "휴대폰을 거실에 두고 열한 시에 누웠다. 생각보다 금방 잠들었다.", listOf("휴식"), hasPhoto = false),
        entry(20, "엄마와의 긴 통화", "한 시간 넘게 이야기를 들었다. 경청이라는 말이 이런 거구나 싶었다.", listOf("경청"), hasPhoto = true),
        entry(12, "팀 회고에서 솔직하게", "잘 안 된 일을 먼저 꺼냈다. 생각보다 분위기가 편해졌다.", listOf("솔직함"), hasPhoto = false),
    )

    val calendar: List<Journal> = list + listOf(2, 5, 8, 13, 15).map { day ->
        entry(day, "기록 ${day}일", "샘플 본문", listOf("휴식"), hasPhoto = false)
    } + entry(15, "9월의 기록", "샘플 본문", listOf("휴식"), hasPhoto = false, month = 9)

    /** Other entries with "경청", shown in the keyword sheet of the detail previews. */
    val detailKeyword: List<Journal> = listOf(
        entry(20, "엄마와의 긴 통화", "한 시간 넘게 이야기를 들었다.", listOf("경청"), hasPhoto = false),
        entry(12, "팀 회고에서 먼저 묻기", "잘 안 된 일을 먼저 물었다.", listOf("경청", "솔직함"), hasPhoto = false),
        entry(5, "후배의 고민을 끝까지 듣다", "조언보다 질문을 먼저 했다.", listOf("경청"), hasPhoto = false),
        entry(30, "독서 모임에서 질문만 하기", "내 생각은 아껴 두었다.", listOf("경청"), hasPhoto = false, month = 9),
        entry(21, "주말 가족 저녁", "동생 이야기를 오래 들었다.", listOf("경청"), hasPhoto = false, month = 9),
        entry(14, "첫 1:1 면담", "말을 줄이고 메모를 했다.", listOf("경청"), hasPhoto = false, month = 9),
    )

    /** 1–2 entries, one written today at 8:12 ("todayJournalExist" on 오늘). */
    val homeEarly: List<Journal> = listOf(
        entry(30, "비 오기 전 산책", "하늘이 낮게 깔려서 우산을 챙겼는데 결국 비는 오지 않았다. 덕분에 천천히 걸었다.", listOf("휴식"), hasPhoto = false)
            .copy(createdAt = Instant.parse("2026-10-29T23:12:00Z")),
        entry(29, "퇴근길 산책", "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.", listOf("꾸준함"), hasPhoto = true),
    )

    /** 일기 앱 모드 on 오늘: entries on Mon 26, Tue 27, Thu 29 and nothing today. */
    val homeDiary: List<Journal> = listOf(
        entry(29, "퇴근길 산책", "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.", emptyList(), hasPhoto = true),
        entry(27, "회의에서 말을 끊지 않기", "끝까지 듣고 나니 내가 하려던 질문이 달라졌다.", emptyList(), hasPhoto = false),
        entry(26, "월요일의 작은 감사", "출근길에 커피를 건네준 동료에게 고맙다고 제대로 말했다.", emptyList(), hasPhoto = false),
    )

    val search: List<Journal> = listOf(
        entry(27, "회의에서 말을 끊지 않기", "오늘은 경청해 보기로 했다. 끝까지 듣고 나니 내가 하려던 질문이 달라졌다.", listOf("경청", "솔직함"), hasPhoto = false),
        entry(20, "엄마와의 긴 통화", "저녁을 먹고 오랜만에 엄마에게 전화를 걸었다. 안부만 묻고 끊으려 했는데 이야기가 길어졌다. 별일 아니라고 하시면서도 목소리가 평소와 달랐다. 한 시간 넘게 이야기를 들었다. 경청이라는 말이 이런 거구나 싶었다.", listOf("경청"), hasPhoto = false),
    )
}

private fun entry(
    day: Int,
    title: String,
    body: String,
    keywords: List<String>,
    hasPhoto: Boolean,
    month: Int = 10,
): Journal {
    val createdAt = Instant.parse("2026-10-27T12:00:00Z")
    return Journal(
        day = LocalDate.of(2026, month, day),
        createdAt = createdAt,
        title = title,
        body = body,
        photos = if (hasPhoto) listOf(JournalPhoto(fileName = "day$day.jpg")) else emptyList(),
        keywords = keywords.mapIndexed { index, name ->
            JournalKeyword(name, KeywordSource.AI, influence = if (index == 0) 0.9 else 0.6)
        },
        analysisState = AnalysisState.Analyzed(createdAt),
    )
}
