//
//  HomeView.swift
//  MPA_ios
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    @Environment(\.productRepository) private var repository
    @Environment(\.isDeviceiPad) private var isDeviceiPad
    @Environment(\.isDeviceiPhoneDuo) private var isDeviceiPhoneDuo
    @Environment(\.contentsEnvironment) private var contentsEnvironment
    
    @State private var showEditor = false
    @State private var path: [Product] = []
    
    var body: some View {
        Group {
            switch contentsEnvironment {
            case .horizontalDuoSplit:
                iphoneDuoSplitView
            case .verticalDuoOverlay:
                iphoneDuoOverlayView
            case .navigationSplit:
                navigationSplitView
            case .generalVertical:
                navigationStackWithDestination
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            JournalEditorView(viewModel: viewModel, onClose: { showEditor = false })
        }
    }
    
    @ViewBuilder
    private var iphoneDuoSplitView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            } secondary: {
                navigationStackWithDestination
            }
            .arrangementViewStyle(.split)
        } else {
            navigationContentView
        }
    }
    
    @ViewBuilder
    private var iphoneDuoOverlayView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                navigationStackWithDestination
            } secondary: {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            }
            .arrangementViewStyle(.overlay)
        } else {
            navigationContentView
        }
    }
    
    /// - Contents
    private var navigationStackWithDestination: some View {
        NavigationStack(path: $path) {
            SplitTodayListView(showEditor: $showEditor, repository: repository, path: $path)
                .navigationDestination(for: Product.self) { product in
                    DailyJournalView(repository: repository, entry: product)
                        .environment(\.journalPaths, $path)
                }
        }
    }
    
    private var navigationSplitView: some View {
        NavigationSplitView {
            MainDateList(repository: repository, $path)
                .modelContainer(for: Product.self, inMemory: true)
        } detail: {
            SplitTodayListView(showEditor: $showEditor, repository: repository, path: $path)
                .navigationDestination(for: Product.self) { product in
                    DailyJournalView(repository: repository, entry: product)
                        .environment(\.journalPaths, $path)
                }
        }
    }
    
    private var navigationContentView: some View {
        NavigationStack(path: $path) {
            ScrollView {
                SplitTodayListView(showEditor: $showEditor, repository: repository, path: $path)
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
                    .addToolbar(MainDateListViewModel(repository: repository), showEditor: $showEditor, path: $path)
            }
            .navigationDestination(for: Product.self) { product in
                DailyJournalView(repository: repository, entry: product)
                    .environment(\.journalPaths, $path)
            }
        }
    }
    
    struct SplitTodayListView: View {
        @Binding var showEditor: Bool
        var repository: any ProductRepositoryProtocol
        @Binding var path: [Product]
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GreetingHeader()
                    Spacer().frame(height: 16)
                    JournalQuestionCard()
                    Spacer().frame(height: 8)
                    // BubbleView
                    JournalReflectionCard()
                    Spacer().frame(height: 20)
                    MyWishSection()
                    Spacer().frame(height: 16)
                    NextWeeksSummaryCard()
                    Spacer().frame(height: 16)
                    TodayJournalPromptCard()
                    Spacer().frame(height: 16)
                    ThisWeekCalendarStrip()
                    Spacer().frame(height: 16)
                    RecentJournalSection()
                    Spacer().frame(height: 36)
                }
                .padding()
            }
            .addToolbar(MainDateListViewModel(repository: repository), showEditor: $showEditor, path: $path)
        }
    }
}

private struct GreetingHeader: View {
    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("좋은 아침이에요")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Text(todayDateText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.TEXT_TERTIARY)
        }
    }
}

private struct AiCard<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        content()
            .padding(16)
            .background(Color.AI_TINT)
            .border(Color.HAIRLINE, width: 1)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AiLabel: View {
    var title: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.AI_ACCENT)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.AI_ACCENT)
        }
    }
}

private struct ChipPill: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.TEXT_PRIMARY)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().stroke(Color.HAIRLINE, lineWidth: 1))
    }
}

private struct PillButton: View {
    var title: String
    var isFilled: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isFilled ? Color.BRAND_ON_PRIMARY : Color.TEXT_SECONDARY)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isFilled ? Color.BRAND_PRIMARY : Color.clear)
                .overlay(Capsule().stroke(isFilled ? Color.clear : Color.HAIRLINE, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct JournalQuestionCard: View {
    var body: some View {
        AiCard {
            VStack(alignment: .leading, spacing: 12) {
                AiLabel(title: "오늘의 조언")
                Text("오늘 일기에 '끝까지 듣기'가 자주 보여요. 오늘은 대화가 끝나길 기다리며, 상대의 말이 끝난 뒤 질문을 하나만 더 건네 보는 건 어때요?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                HStack {
                    Text("참고한 일기")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.TEXT_TERTIARY)
                    Spacer()
                    HStack(spacing: 8) {
                        ChipPill(text: "10월 20일")
                        ChipPill(text: "10월 27일")
                    }
                }
                HStack {
                    Text("🔺 5가지 내 새로운 생성됨")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                        Image(systemName: "hand.thumbsdown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                    }
                }
            }
        }
    }
}

private struct JournalReflectionCard: View {
    var body: some View {
        AiCard {
            VStack(alignment: .leading, spacing: 12) {
                AiLabel(title: "오늘의 걸음")
                Text("오늘은 누군가의 말을 끝까지 들었던 순간이 있었나요?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                HStack(spacing: 8) {
                    PillButton(title: "이 질문으로 쓰기", isFilled: true, action: {})
                    PillButton(title: "다른 질문", isFilled: false, action: {})
                }
            }
        }
    }
}

private struct MyWishSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("나의 원칙")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Spacer()
                Text("전체 보기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.BRAND_PRIMARY)
            }
            Text("일기 12개에서 찾았어요")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.TEXT_TERTIARY)
            BubbleCloud()
            BubbleLegend()
        }
    }
}

private struct BubbleCloud: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                PrincipleBubble(label: "무조함", size: 64, color: Color.PRINCIPLE5)
                Spacer(minLength: 8)
                PrincipleBubble(label: "경청", size: 100, color: Color.PRINCIPLE1)
                Spacer(minLength: 8)
                PrincipleBubble(label: "솔직함", size: 72, color: Color.PRINCIPLE4)
            }
            HStack {
                PrincipleBubble(label: "휴식", size: 80, color: Color.PRINCIPLE3)
                Spacer(minLength: 8)
                PrincipleBubble(label: "감사", size: 68, color: Color.PRINCIPLE2)
            }
        }
    }
}

private struct BubbleLegend: View {
    private let colors: [Color] = [
        Color.PRINCIPLE1, Color.PRINCIPLE2, Color.PRINCIPLE3, Color.PRINCIPLE4, Color.PRINCIPLE5,
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text("최근")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)
                ForEach(colors.indices, id: \.self) { index in
                    Circle()
                        .fill(colors[index])
                        .frame(width: 8, height: 8)
                }
                Text("오래된")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)
            }
            Text("크기 = 등장 빈도")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.TEXT_TERTIARY)
        }
    }
}

private struct PrincipleBubble: View {
    var label: String
    var size: CGFloat
    var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ON_PRINCIPLE)
        }
    }
}

private struct NextWeeksSummaryCard: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("이전 주 요약")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text("10월 26일~30일 · 일기 4개 · 서분형이 늘었어요")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.TEXT_PRIMARY)
        }
        .padding(16)
        .background(Color.SUNKEN)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.HAIRLINE, lineWidth: 1))
    }
}

private struct TodayJournalPromptCard: View {
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 8) {
                Text("오늘의 일기")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.TEXT_TERTIARY)
                Text("오늘 하루를 몇 줄로 남겨보세요")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text("짧아도 괜찮아요. 오른쪽 아래 '쓰기'를 눌러 시작하세요.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.SURFACE)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.HAIRLINE, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct ThisWeekCalendarStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("이번 주")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Spacer()
                Button(action: {}) {
                    Text("캘린더")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.BRAND_PRIMARY)
                }
                .buttonStyle(.plain)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    WeekDayColumn(weekday: "월", day: "26", hasJournal: true)
                    WeekDayColumn(weekday: "화", day: "27", hasJournal: true)
                    WeekDayColumn(weekday: "수", day: "28", hasJournal: false)
                    WeekDayColumn(weekday: "목", day: "29", hasJournal: true)
                    WeekDayColumn(weekday: "금", day: "30", hasJournal: false, isSelected: true)
                    WeekDayColumn(weekday: "토", day: "31", hasJournal: false, isCurrentWeek: false)
                    WeekDayColumn(weekday: "일", day: "1", hasJournal: false, isCurrentWeek: false)
                }
            }
        }
    }
}

private struct WeekDayColumn: View {
    var weekday: String
    var day: String
    var hasJournal: Bool = false
    var isCurrentWeek: Bool = true
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(weekday)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isCurrentWeek ? Color.TEXT_SECONDARY : Color.TEXT_TERTIARY)
            Text(day)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(isCurrentWeek ? Color.TEXT_PRIMARY : Color.TEXT_TERTIARY)
            if hasJournal {
                Circle()
                    .fill(Color.BRAND_PRIMARY)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 50, height: 64)
        .background(isSelected ? Color.BRAND_CONTAINER : Color.clear)
        .cornerRadius(12)
    }
}

private struct RecentJournalSection: View {
    var items: [RecentJournalItem] = [
        RecentJournalItem(day: "29", weekday: "목", title: "퇴근길 산책", preview: "한 정거장 먼저 내려서 걸었다. 바람이 차가워서 오히려 머리가 맑아졌다.", hasPhoto: true),
        RecentJournalItem(day: "27", weekday: "화", title: "회의에서 말을 끊지 않기", preview: "끝까지 듣고 나니 내가 하려던 질문이 달라졌다.", hasPhoto: false),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("최근 기록")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Spacer()
                Text("모두 보기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            ForEach(items) { item in
                RecentJournalRow(item: item)
                    .padding(.vertical, 12)
                if let lastItem = items.last, item.id != lastItem.id {
                    Divider()
                        .background(Color.HAIRLINE)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct RecentJournalItem: Identifiable {
    let id = UUID()
    let day: String
    let weekday: String
    let title: String
    let preview: String
    let hasPhoto: Bool
}

private struct RecentJournalRow: View {
    var item: RecentJournalItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Text(item.day)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text(item.weekday)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.TEXT_TERTIARY)
            }
            .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineLimit(1)
                Text(item.preview)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .lineLimit(2)
            }
            if item.hasPhoto {
                Spacer()
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)
                    .frame(width: 56, height: 56)
                    .background(Color.SUNKEN)
                    .cornerRadius(10)
            }
        }
    }
}

//#Preview {
//    HomeView(viewModel: JournalViewModel(productRepository: MockProductRepository()))
//}
