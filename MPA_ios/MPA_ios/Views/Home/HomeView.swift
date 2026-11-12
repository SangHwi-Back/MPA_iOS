//
//  HomeView.swift
//  MPA_ios
//

import SwiftUI

/// A request to open the editor: today's date by default, optionally with a 글감 question on top.
struct HomeEditorRequest: Identifiable {
    let id = UUID()
    var date: Date? = nil
    var prompt: String? = nil
}

struct HomeView: View {
    @Binding var selectedTab: ContentTab
    @Binding var isSettingsDetailPresented: Bool
    
    @Environment(HomeViewModel.self) private var homeViewModel
    @Environment(JournalViewModel.self) private var journalViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.contentsEnvironment) private var contentsEnvironment
    
    @State private var editorRequest: HomeEditorRequest?
    @State private var openedEntryID: UUID?
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
                homeStack
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
        .onChange(of: journalViewModel.entries.map(\.id), initial: true) {
            homeViewModel.entries = journalViewModel.entries
            homeViewModel.now = .now
        }
        .onChange(of: settingsViewModel.aiConnection, initial: true) {
            homeViewModel.aiStatus = HomeAIStatus(connection: settingsViewModel.aiConnection)
        }
        .task(id: TaskKey(entryIDs: journalViewModel.entries.map(\.id), status: homeViewModel.aiStatus)) {
            await homeViewModel.load()
        }
        .onAppear {
            homeViewModel.entries = journalViewModel.entries
        }
    }
    
    private struct TaskKey: Equatable {
        let entryIDs: [UUID]
        let status: HomeAIStatus
    }
    
    // MARK: - Layouts
    
    private var homeStack: some View {
        NavigationStack {
            content
                .navigationDestination(item: $openedEntryID) { id in detail(id) }
        }
    }
    
    @ViewBuilder
    private var navigationSplitView: some View {
        NavigationSplitView {
            HomeSidebarView(
                today: homeViewModel.today,
                onOpen: openEntry,
                onSeeAll: { selectedTab = .journal }
            )
            .navigationSplitViewColumnWidth(320)
        } detail: {
            homeStack
        }
    }
    
    @ViewBuilder
    private var iphoneDuoSplitView: some View {
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
                    homeStack
                }
                .arrangementViewStyle(.split)
            }
        } else {
            homeStack
        }
    }
    
    @ViewBuilder
    private var iphoneDuoOverlayView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                MainDateList($path)
                    .modelContainer(for: Product.self, inMemory: true)
            } secondary: {
                homeStack
            }
            .arrangementViewStyle(.overlay)
        } else {
            homeStack
        }
    }
    
    private var content: some View {
        HomeContentView(
            onWrite: { editorRequest = HomeEditorRequest(date: $0, prompt: $1) },
            onOpenEntry: openEntry,
            onSelectTab: { selectedTab = $0 },
            onConnectKey: {
                selectedTab = .settings
                isSettingsDetailPresented = true
            }
        )
    }
    
    // MARK: - Navigation
    
    private func openEntry(_ entry: Journal) {
        openedEntryID = entry.id
    }
    
    @ViewBuilder
    private func detail(_ id: UUID) -> some View {
        if let entry = journalViewModel.entries.first(where: { $0.id == id }) {
            JournalDetailView(
                journal: entry,
                onOpenEntry: openEntry,
                onDelete: { deleted in
                    openedEntryID = nil
                    journalViewModel.delete(deleted)
                },
                onOpenPrinciple: { _ in selectedTab = .principles }
            )
        }
    }
}

// MARK: - Content

/// The scrolling 오늘 page. Stateless apart from scroll position; everything else lives in `HomeViewModel`.
struct HomeContentView: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    let onConnectKey: () -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    @State private var isHeaderScrolledAway = false
    
    private var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeLayoutMetrics.sectionSpacing) {
                HomeGreetingHeader(dateLine: homeViewModel.dateLine, greeting: homeViewModel.greeting)
                    .padding(.bottom, 4)
                if isRegular, homeViewModel.layout == .full || homeViewModel.layout == .early {
                    regularColumns
                } else {
                    sections
                }
            }
            .padding(.horizontal, HomeLayoutMetrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: isRegular ? 1100 : HomeLayoutMetrics.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color.CANVAS)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 72
        } action: { _, isHidden in
            isHeaderScrolledAway = isHidden
        }
        .navigationTitle(isHeaderScrolledAway ? "오늘" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(
            homeViewModel.aiStatus.unavailableReason?.homeAlertTitle ?? "",
            isPresented: Binding(get: {
                homeViewModel.isAlertPresented
            }, set: {
                homeViewModel.isAlertPresented = $0
            }),
            presenting: homeViewModel.aiStatus.unavailableReason
        ) { _ in
            Button("API 키 연결", action: onConnectKey)
            Button("확인") {}
                .keyboardShortcut(.defaultAction)
        } message: { reason in
            Text(reason.homeAlertMessage)
        }
    }
    
    // MARK: Toolbar (3.1, 3.12)
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !homeViewModel.aiStatus.isAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    homeViewModel.isAlertPresented = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.WARNING)
                .accessibilityLabel(homeViewModel.aiStatus.unavailableReason?.homeAlertTitle ?? "AI 경고")
                .transition(.scale.combined(with: .opacity))
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // An existing entry for today should open in edit mode; the editor cannot load one yet.
                onWrite(nil, nil)
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .accessibilityLabel("새 일기")
        }
    }
    
    // MARK: Phone sections (state matrix)
    
    @ViewBuilder
    private var sections: some View {
        switch homeViewModel.layout {
        case .firstRun:
            firstRun
        case .early:
            adviceCard
            todayCard
            HomePrincipleProgressSection(entryCount: homeViewModel.entries.count)
                .padding(.top, 16)
        case .full:
            adviceCard
            todayCard
            principles
                .padding(.top, 24)
            if homeViewModel.showsWeeklySummary {
                weeklySummary(isAlwaysExpanded: false)
                    .padding(.top, 8)
            }
        case .diary:
            diaryTodayCard
            HomeWeekStrip(
                days: homeViewModel.weekDays,
                onSelect: selectWeekDay,
                onOpenCalendar: { onSelectTab(.journal) },
                onChangeWeek: { delta in
                    withAnimation { homeViewModel.weekOffset = min(0, homeViewModel.weekOffset + delta) }
                }
            )
            .padding(.top, 16)
            HomeRecentSection(entries: homeViewModel.recentEntries, onOpen: onOpenEntry, onSeeAll: { onSelectTab(.journal) })
                .padding(.top, 16)
        }
    }
    
    /// Tablet: advice + 글감 on the left, principles + summary on the right.
    private var regularColumns: some View {
        HStack(alignment: .top, spacing: 48) {
            VStack(spacing: HomeLayoutMetrics.sectionSpacing) {
                adviceCard
                todayCard
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: HomeLayoutMetrics.sectionSpacing) {
                if homeViewModel.layout == .full {
                    HomePrinciplesSection(
                        principles: homeViewModel.principles,
                        entryCount: homeViewModel.entries.count,
                        showsBubbleBackground: true,
                        onSeeAll: { onSelectTab(.principles) },
                        onOpenEntry: onOpenEntry
                    )
                    if homeViewModel.showsWeeklySummary {
                        weeklySummary(isAlwaysExpanded: true)
                    }
                } else {
                    HomePrincipleProgressSection(entryCount: homeViewModel.entries.count)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }
    
    private var firstRun: some View {
        HomeFirstRunSection(
            privacyLine: homeViewModel.privacyLine,
            onQuestion: { onWrite(nil, $0) }
        )
    }
    
    private var adviceCard: some View {
        HomeAdviceCard(
            phase: homeViewModel.advicePhase,
            sources: homeViewModel.advicePhase.text.map(homeViewModel.sources(of:)) ?? [],
            revealsByWord: homeViewModel.revealsAdviceByWord,
            onOpenSource: onOpenEntry,
            onFeedback: homeViewModel.toggleFeedback,
            onRegenerate: { Task { await homeViewModel.regenerateAdvice() } },
            onRetry: { Task { await homeViewModel.generateAdvice() } },
            onCheckKey: onConnectKey,
            onCallHelp: { openURL(URL(string: "tel:109")!) },
            onOpenHelpResources: {}
        )
    }
    
    @ViewBuilder
    private var todayCard: some View {
        if let entry = homeViewModel.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomePromptCard(
                phase: homeViewModel.promptPhase,
                onWrite: { onWrite(nil, $0) },
                onNextPrompt: { Task { await homeViewModel.nextPrompt() } }
            )
        }
    }
    
    @ViewBuilder
    private var diaryTodayCard: some View {
        if let entry = homeViewModel.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomeDiaryTodayCard { onWrite(nil, nil) }
        }
    }
    
    private var principles: some View {
        HomePrinciplesSection(
            principles: homeViewModel.principles,
            entryCount: homeViewModel.entries.count,
            onSeeAll: { onSelectTab(.principles) },
            onOpenEntry: onOpenEntry
        )
    }
    
    private func weeklySummary(isAlwaysExpanded: Bool) -> some View {
        HomeWeeklySummaryCard(
            phase: homeViewModel.summaryPhase,
            rangeLine: homeViewModel.weeklyRangeLine,
            isExpanded: homeViewModel.isSummaryExpanded,
            sources: homeViewModel.summaryPhase.text.map(homeViewModel.sources(of:)) ?? [],
            isAlwaysExpanded: isAlwaysExpanded,
            onToggle: { homeViewModel.isSummaryExpanded.toggle() },
            onRetry: { Task { await homeViewModel.generateSummary() } },
            onOpenSource: onOpenEntry
        )
    }
    
    private func selectWeekDay(_ day: HomeWeekDay) {
        if let entry = HomeViewModel.newestFirst(homeViewModel.entries).first(where: { Calendar.current.isDate($0.day, inSameDayAs: day.date) }) {
            onOpenEntry(entry)
        } else {
            onWrite(day.date, nil)
        }
    }
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
        entries: entries,
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
        entries: entries,
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
