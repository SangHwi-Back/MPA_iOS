//
//  Journal+Samples.swift
//  MPA_ios
//

import Foundation

private func sampleDay(_ day: Int) -> Date {
    Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: day))!
}

private func sampleEntry(
    day: Int,
    title: String,
    body: String,
    keywords: [String],
    hasPhoto: Bool
) -> Journal {
    let date = sampleDay(day)
    return Journal(
        day: date,
        createdAt: date,
        title: title,
        body: body,
        photos: hasPhoto ? [JournalPhoto(fileName: "day\(day).jpg")] : [],
        keywords: keywords.enumerated().map { item in
            JournalKeyword(name: item.element, source: .ai, influence: item.offset == 0 ? 0.9 : 0.6)
        },
        analysisState: .analyzed(at: date)
    )
}

// MARK: - Design example data for the 기록 previews

extension Journal {
    static var listSamples: [Journal] {
        [
            sampleEntry(day: 30, title: "비 오기 전 산책", body: "하늘이 낮게 깔려서 우산을 챙겼는데 결국 비는 오지 않았다. 덕분에 천천히 걸었다.", keywords: ["휴식", "꾸준함"], hasPhoto: true),
            sampleEntry(day: 29, title: "퇴근길 산책", body: "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.", keywords: ["꾸준함"], hasPhoto: true),
            sampleEntry(day: 27, title: "회의에서 말을 끊지 않기", body: "끝까지 듣고 나니 내가 하려던 질문이 달라졌다. 다음 회의에도 먼저 묻고 말해야겠다.", keywords: ["경청", "솔직함"], hasPhoto: false),
            sampleEntry(day: 26, title: "월요일의 작은 감사", body: "출근길에 커피를 건네준 동료에게 고맙다고 제대로 말했다.", keywords: ["감사"], hasPhoto: false),
            sampleEntry(day: 22, title: "일찍 잠들기", body: "휴대폰을 거실에 두고 열한 시에 누웠다. 생각보다 금방 잠들었다.", keywords: ["휴식"], hasPhoto: false),
            sampleEntry(day: 20, title: "엄마와의 긴 통화", body: "한 시간 넘게 이야기를 들었다. 경청이라는 말이 이런 거구나 싶었다.", keywords: ["경청"], hasPhoto: true),
            sampleEntry(day: 12, title: "팀 회고에서 솔직하게", body: "잘 안 된 일을 먼저 꺼냈다. 생각보다 분위기가 편해졌다.", keywords: ["솔직함"], hasPhoto: false),
        ]
    }

    static var calendarSamples: [Journal] {
        listSamples + [2, 5, 8, 13, 15].map { day in
            sampleEntry(day: day, title: "기록 \(day)일", body: "샘플 본문", keywords: ["휴식"], hasPhoto: false)
        }
    }

    static var searchSamples: [Journal] {
        [
            sampleEntry(day: 27, title: "회의에서 말을 끊지 않기", body: "오늘은 경청해 보기로 했다. 끝까지 듣고 나니 내가 하려던 질문이 달라졌다.", keywords: ["경청", "솔직함"], hasPhoto: false),
            sampleEntry(day: 20, title: "엄마와의 긴 통화", body: "저녁을 먹고 오랜만에 엄마에게 전화를 걸었다. 안부만 묻고 끊으려 했는데 이야기가 길어졌다. 별일 아니라고 하시면서도 목소리가 평소와 달랐다. 한 시간 넘게 이야기를 들었다. 경청이라는 말이 이런 거구나 싶었다.", keywords: ["경청"], hasPhoto: false),
        ]
    }
}
