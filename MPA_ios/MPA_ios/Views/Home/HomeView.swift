//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
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
    @ObservedObject var viewModel: JournalViewModel
    var settingsViewModel: SettingsViewModel
    @Binding var selectedTab: ContentTab
    @Binding var isSettingsDetailPresented: Bool

    @Environment(\.productRepository) private var repository
    @Environment(\.contentsEnvironment) private var contentsEnvironment

    @State private var home: HomeViewModel
    @State private var editorRequest: HomeEditorRequest?
    @State private var openedEntryID: UUID?
    @State private var path: [Product] = []

    init(
        viewModel: JournalViewModel,
        settingsViewModel: SettingsViewModel,
        selectedTab: Binding<ContentTab>,
        isSettingsDetailPresented: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self.settingsViewModel = settingsViewModel
        self._selectedTab = selectedTab
        self._isSettingsDetailPresented = isSettingsDetailPresented
        self._home = State(initialValue: HomeViewModel(
            entries: viewModel.entries,
            aiStatus: HomeAIStatus(connection: settingsViewModel.aiConnection)
        ))
    }

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
                viewModel: viewModel,
                initialDate: request.date,
                initialPrompt: request.prompt,
                onClose: { editorRequest = nil }
            )
            .presentationDetents([.large])
        }
        .sensoryFeedback(.impact(weight: .light), trigger: editorRequest?.id)
        .onChange(of: viewModel.entries.map(\.id), initial: true) {
            home.entries = viewModel.entries
            home.now = .now
        }
        .onChange(of: settingsViewModel.aiConnection, initial: true) {
            home.aiStatus = HomeAIStatus(connection: settingsViewModel.aiConnection)
        }
        .task(id: TaskKey(entryIDs: viewModel.entries.map(\.id), status: home.aiStatus)) {
            await home.load()
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

    private var navigationSplitView: some View {
        NavigationSplitView {
            HomeSidebarView(
                viewModel: viewModel,
                today: home.today,
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
            ArrangementView {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            } secondary: {
                homeStack
            }
            .arrangementViewStyle(.split)
        } else {
            homeStack
        }
    }

    @ViewBuilder
    private var iphoneDuoOverlayView: some View {
        if #available(anyAppleOS 27.1, *) {
            ArrangementView {
                homeStack
            } secondary: {
                MainDateList(repository: repository, $path)
                    .modelContainer(for: Product.self, inMemory: true)
            }
            .arrangementViewStyle(.overlay)
        } else {
            homeStack
        }
    }

    private var content: some View {
        HomeContentView(
            model: home,
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
        if let entry = viewModel.entries.first(where: { $0.id == id }) {
            JournalDetailView(
                journal: entry,
                journalViewModel: viewModel,
                onOpenEntry: openEntry,
                onDelete: { deleted in
                    openedEntryID = nil
                    viewModel.delete(deleted)
                },
                onOpenPrinciple: { _ in selectedTab = .principles }
            )
        }
    }
}

// MARK: - Content

/// The scrolling 오늘 page. Stateless apart from scroll position; everything else lives in `HomeViewModel`.
struct HomeContentView: View {
    @Bindable var model: HomeViewModel
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    let onConnectKey: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    @State private var isHeaderScrolledAway = false

    private var isRegular: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeLayoutMetrics.sectionSpacing) {
                HomeGreetingHeader(dateLine: model.dateLine, greeting: model.greeting)
                    .padding(.bottom, 4)
                if isRegular, model.layout == .full || model.layout == .early {
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
            model.aiStatus.unavailableReason?.homeAlertTitle ?? "",
            isPresented: $model.isAlertPresented,
            presenting: model.aiStatus.unavailableReason
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
        if !model.aiStatus.isAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.isAlertPresented = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.WARNING)
                .accessibilityLabel(model.aiStatus.unavailableReason?.homeAlertTitle ?? "AI 경고")
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
        switch model.layout {
        case .firstRun:
            firstRun
        case .early:
            adviceCard
            todayCard
            HomePrincipleProgressSection(entryCount: model.entries.count)
                .padding(.top, 16)
        case .full:
            adviceCard
            todayCard
            principles
                .padding(.top, 24)
            if model.showsWeeklySummary {
                weeklySummary(isAlwaysExpanded: false)
                    .padding(.top, 8)
            }
        case .diary:
            diaryTodayCard
            HomeWeekStrip(
                days: model.weekDays,
                onSelect: selectWeekDay,
                onOpenCalendar: { onSelectTab(.journal) },
                onChangeWeek: { delta in
                    withAnimation { model.weekOffset = min(0, model.weekOffset + delta) }
                }
            )
            .padding(.top, 16)
            HomeRecentSection(entries: model.recentEntries, onOpen: onOpenEntry, onSeeAll: { onSelectTab(.journal) })
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
                if model.layout == .full {
                    HomePrinciplesSection(
                        principles: model.principles,
                        entryCount: model.entries.count,
                        showsBubbleBackground: true,
                        onSeeAll: { onSelectTab(.principles) },
                        onOpenEntry: onOpenEntry
                    )
                    if model.showsWeeklySummary {
                        weeklySummary(isAlwaysExpanded: true)
                    }
                } else {
                    HomePrincipleProgressSection(entryCount: model.entries.count)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }

    private var firstRun: some View {
        HomeFirstRunSection(
            privacyLine: privacyLine,
            onWrite: { onWrite(nil, nil) },
            onQuestion: { onWrite(nil, $0) }
        )
    }

    private var privacyLine: String? {
        switch model.aiStatus {
        case .unavailable: return nil
        case .available(let engine), .keyError(let engine):
            return engine.isOnDevice ? "모든 분석은 이 기기 안에서 이루어져요" : "요약·키워드만 \(engine == .openAIAPIKey ? "OpenAI" : "Gemini")(내 키)로 전송돼요"
        }
    }

    private var adviceCard: some View {
        HomeAdviceCard(
            phase: model.advicePhase,
            sources: model.advicePhase.text.map(model.sources(of:)) ?? [],
            revealsByWord: model.revealsAdviceByWord,
            onOpenSource: onOpenEntry,
            onFeedback: model.toggleFeedback,
            onRegenerate: { Task { await model.regenerateAdvice() } },
            onRetry: { Task { await model.generateAdvice() } },
            onCheckKey: onConnectKey,
            onCallHelp: { openURL(URL(string: "tel:109")!) },
            onOpenHelpResources: {}
        )
    }

    @ViewBuilder
    private var todayCard: some View {
        if let entry = model.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomePromptCard(
                phase: model.promptPhase,
                onWrite: { onWrite(nil, $0) },
                onNextPrompt: { Task { await model.nextPrompt() } }
            )
        }
    }

    @ViewBuilder
    private var diaryTodayCard: some View {
        if let entry = model.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomeDiaryTodayCard { onWrite(nil, nil) }
        }
    }

    private var principles: some View {
        HomePrinciplesSection(
            principles: model.principles,
            entryCount: model.entries.count,
            onSeeAll: { onSelectTab(.principles) },
            onOpenEntry: onOpenEntry
        )
    }

    private func weeklySummary(isAlwaysExpanded: Bool) -> some View {
        HomeWeeklySummaryCard(
            phase: model.summaryPhase,
            rangeLine: model.weeklyRangeLine,
            isExpanded: model.isSummaryExpanded,
            sources: model.summaryPhase.text.map(model.sources(of:)) ?? [],
            isAlwaysExpanded: isAlwaysExpanded,
            onToggle: { model.isSummaryExpanded.toggle() },
            onRetry: { Task { await model.generateSummary() } },
            onOpenSource: onOpenEntry
        )
    }

    private func selectWeekDay(_ day: HomeWeekDay) {
        if let entry = HomeViewModel.newestFirst(model.entries).first(where: { Calendar.current.isDate($0.day, inSameDayAs: day.date) }) {
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
            HomeContentView(model: model, onWrite: { _, _ in }, onOpenEntry: { _ in }, onSelectTab: { _ in }, onConnectKey: {})
        }
    }
}

@MainActor
private func homeSidebarPreviewModel(entries: [Journal]) -> JournalViewModel {
    let viewModel = JournalViewModel()
    viewModel.today = Calendar.current.startOfDay(for: homePreviewDate())
    viewModel.entries = entries
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
        HomeSidebarView(viewModel: homeSidebarPreviewModel(entries: Journal.homeSamples), today: homePreviewDate(), onOpen: { _ in }, onSeeAll: {})
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
    }
}

#Preview("tablet-drawerCalendarButtonTapped", traits: .landscapeLeft) {
    NavigationSplitView {
        HomeSidebarView(
            viewModel: homeSidebarPreviewModel(entries: Journal.homeSamples),
            today: homePreviewDate(),
            isCalendarMode: true,
            selectedDay: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 27)),
            onOpen: { _ in },
            onSeeAll: {}
        )
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: homeFullSamples))
    }
}

#Preview("tablet-emptyJournals", traits: .landscapeLeft) {
    NavigationSplitView {
        HomeSidebarView(viewModel: homeSidebarPreviewModel(entries: []), today: homePreviewDate(), onOpen: { _ in }, onSeeAll: {})
    } detail: {
        HomePreviewHost(model: homePreviewModel(entries: []))
    }
}
