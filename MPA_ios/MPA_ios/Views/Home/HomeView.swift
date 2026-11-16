//
//  HomeView.swift
//  MPA_ios
//

import SwiftUI

/*
 # uitest
 ## 개요
 - HomeView 는 기기의 상태에 따라 적절한 화면을 보여주는 역할
 ## 용어 정리
 - 없음
 ## 테스트할 요소
 - iPhone 세로: `home.screen` 이 보이고 `home.drawer` 는 없다
 - iPhone 가로로 돌리면: `home.drawer` 와 `home.screen` 이 함께 보인다
 - iPad: `home.drawer` 와 `home.screen` 가 보인다
 - 공통 : `home.newJournalButton` 가 보인다
 ## 제외
 - iPhone Duo: 시뮬레이터에서 힌지 상태를 만들 수 없음 (수동 확인)
 */

struct HomeView: View {
    @Binding var selectedTab: ContentTab
    @Binding var isSettingsDetailPresented: Bool
    
    @Environment(HomeViewModel.self) private var homeViewModel
    
    @Environment(\.hingeStatus)
    private var hingeStatus
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    
    @State private var editorRequest: HomeEditorRequest?
    @State private var openedEntryID: UUID?
    
    var body: some View {
        Group {
            if let hingeStatus {
                if hingeStatus == .closed {
                    if verticalSizeClass == .regular {
                        HomeContent
                    } else {
                        HomeSidebarNavigationSplit
                    }
                } else {
                    HomeIphoneDuoSplit
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                HomeSidebarNavigationSplit
            } else {
                if verticalSizeClass == .compact {
                    HomeSidebarNavigationSplit
                } else {
                    HomeContent
                }
            }
        }
        .sheet(item: $editorRequest) { request in
            JournalEditorView(
                initialDate: request.date,
                initialPrompt: request.prompt,
                onClose: { editorRequest = nil }
            )
            .presentationDetents([.large])
        }
        .sensoryFeedback(.impact(weight: .light), trigger: editorRequest?.id)
        // Entries come from the shared JournalRepository, so this reruns whenever one is added or deleted.
        .task(id: TaskKey(entryIDs: homeViewModel.entries.map(\.id), status: homeViewModel.aiStatus)) {
            homeViewModel.now = .now
            await homeViewModel.load()
        }
    }
    
    private struct TaskKey: Equatable {
        let entryIDs: [UUID]
        let status: HomeAIStatus
    }
    
    // MARK: - Layouts
    
    @ViewBuilder
    private var HomeSidebarNavigationSplit: some View {
        NavigationSplitView {
            HomeSidebarView(
                today: homeViewModel.today,
                onOpen: openEntry,
                onSeeAll: { selectedTab = .journal }
            )
            .navigationSplitViewColumnWidth(320)
        } detail: {
            HomeContent
        }
    }
    
    @ViewBuilder
    private var HomeIphoneDuoSplit: some View {
        if #available(anyAppleOS 27.1, *) {
            if homeViewModel.entries.isEmpty {
                HomeFirstRunSection(
                    privacyLine: homeViewModel.privacyLine,
                    onQuestion: { question in editorRequest = HomeEditorRequest(date: .now, prompt: question) }
                )
                .padding()
            } else {
                ArrangementView {
                    HomeSidebarView(
                        today: homeViewModel.today,
                        onOpen: openEntry,
                        onSeeAll: { selectedTab = .journal }
                    )
                    .navigationSplitViewColumnWidth(320)
                } secondary: {
                    HomeContent
                }
                .arrangementViewStyle(.split)
            }
        } else {
            HomeContent
        }
    }
    
    private var HomeContent: some View {
        NavigationStack {
            HomeContentView(
                onWrite: { editorRequest = HomeEditorRequest(date: $0, prompt: $1) },
                onOpenEntry: openEntry,
                onSelectTab: { selectedTab = $0 },
                onConnectKey: {
                    selectedTab = .settings
                    isSettingsDetailPresented = true
                }
            )
            .navigationDestination(item: $openedEntryID) { id in detail(id) }
        }
    }
    
    // MARK: - Navigation
    
    private func openEntry(_ entry: Journal) {
        openedEntryID = entry.id
    }
    
    @ViewBuilder
    private func detail(_ id: UUID) -> some View {
        if let entry = homeViewModel.entries.first(where: { $0.id == id }) {
            JournalDetailView(
                journal: entry,
                onOpenEntry: openEntry,
                onDelete: { _ in openedEntryID = nil },
                onOpenPrinciple: { _ in selectedTab = .principles }
            )
        }
    }
}

/// A request to open the editor: today's date by default, optionally with a 글감 question on top.
struct HomeEditorRequest: Identifiable {
    let id = UUID()
    var date: Date? = nil
    var prompt: String? = nil
}

// MARK: - Previews

@MainActor
private func homePreviewDate(hour: Int = 8, minute: Int = 12) -> Date {
    Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: hour, minute: minute))!
}

@MainActor
private func homePreviewModel(
    entries: [Journal],
    status: HomeAIStatus = .available(.appleIntelligence),
    isAlertPresented: Bool = false
) -> HomeViewModel {
    let generator = StubHomeAIGenerator(delay: .seconds(3600))
    let model = HomeViewModel(
        repository: InMemoryJournalRepository(journals: entries),
        aiStatus: status,
        now: homePreviewDate(),
        generator: generator,
        isAlertPresented: isAlertPresented
    )
    guard status.isAvailable, !entries.isEmpty else { return model }
    let sources = entries.count < 3
    ? HomeViewModel.newestFirst(entries).prefix(2).map(\.id)
    : entries.filter { [20, 27].contains(Calendar.current.component(.day, from: $0.day)) }.map(\.id)
    return HomeViewModel(
        repository: InMemoryJournalRepository(journals: entries),
        aiStatus: status,
        now: homePreviewDate(),
        generator: generator,
        advice: AIText(
            text: entries.count < 3 ? HomeSamples.shortAdvice : HomeSamples.advice,
            engine: status.engine ?? .appleIntelligence,
            generatedAt: homePreviewDate(),
            sourceJournalIDs: Array(sources),
            feedback: nil
        ),
        writingPrompt: HomeSamples.writingPrompt,
        weeklySummary: AIText(
            text: HomeSamples.weeklySummary,
            engine: .appleIntelligence,
            generatedAt: homePreviewDate(),
            sourceJournalIDs: [],
            feedback: nil
        ),
        isAlertPresented: isAlertPresented
    )
}

private struct HomePreviewHost: View {
    let model: HomeViewModel
    
    var body: some View {
        NavigationStack {
            HomeContentView(
                onWrite: { _, _ in },
                onOpenEntry: { _ in },
                onSelectTab: { _ in },
                onConnectKey: {}
            )
        }
        .environment(model)
    }
}

@MainActor
private func homeSidebarPreviewModel(entries: [Journal]) -> JournalViewModel {
    let viewModel = JournalViewModel(repository: InMemoryJournalRepository(journals: entries))
    viewModel.today = Calendar.current.startOfDay(for: homePreviewDate())
    viewModel.keywordStageOverride = ["휴식": 0, "경청": 1, "솔직함": 2, "꾸준함": 3, "감사": 4]
    return viewModel
}

/// 3+ entries, none today (Oct 30 is excluded so the 글감 card shows).
@MainActor private var homeFullSamples: [Journal] {
    Journal.homeSamples.filter { Calendar.current.component(.day, from: $0.day) != 30 }
}

#Preview("home") {
    HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
}

#Preview("noJournalToday") {
    HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
}

#Preview("todayJournalExist") {
    HomePreviewHost(model: homePreviewModel(entries: Journal.homeEarlySamples))
}

#Preview("emptyJournals") {
    HomePreviewHost(model: homePreviewModel(entries: []))
}

#Preview("aiNotAvailable") {
    HomePreviewHost(model: homePreviewModel(entries: Journal.homeDiarySamples, status: .unavailable(.unsupported)))
}

#Preview("aiNotAvailableButtonTapped") {
    HomePreviewHost(model: homePreviewModel(
        entries: Journal.homeDiarySamples,
        status: .unavailable(.unsupported),
        isAlertPresented: true
    ))
}

#Preview("bubbleLongTap") {
    // The context menu opens on a long press; render this preview and long-press 경청 to see it.
    HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
}

#Preview("darkMode") {
    HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
        .preferredColorScheme(.dark)
}
#Preview("tablet-todayJournalExist", traits: .landscapeLeft) {
    NavigationSplitView {
        HomeSidebarView(today: homePreviewDate(), onOpen: { _ in }, onSeeAll: {})
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
    }
    .environment(homeSidebarPreviewModel(entries: Journal.homeSamples))
}

#Preview("tablet-drawerCalendarButtonTapped", traits: .landscapeLeft) {
    NavigationSplitView {
        HomeSidebarView(
            today: homePreviewDate(),
            isCalendarMode: true,
            selectedDay: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 27)),
            onOpen: { _ in },
            onSeeAll: {}
        )
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
    }
    .environment(homeSidebarPreviewModel(entries: Journal.homeSamples))
}

#Preview("tablet-emptyJournals", traits: .landscapeLeft) {
    NavigationSplitView {
        HomeSidebarView(today: homePreviewDate(), onOpen: { _ in }, onSeeAll: {})
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: []))
    }
    .environment(homeSidebarPreviewModel(entries: []))
}
