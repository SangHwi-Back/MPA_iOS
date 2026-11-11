//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

private struct JournalEditorRequest: Identifiable {
    let id = UUID()
    let day: Date
}

struct JournalView: View {
    @Bindable var viewModel: JournalViewModel
    /// Opens the entry detail (Part B). When nil, the detail is pushed inside this tab.
    var onOpenEntry: ((Journal) -> Void)? = nil
    /// Opens the editor for an existing entry (Part C).
    var onEditEntry: (Journal) -> Void = { _ in }
    /// Opens the list of entries for a keyword.
    var onOpenKeyword: (String) -> Void = { _ in }
    /// Starts with this row swiped open. Used by previews.
    var initialOpenSwipeRowID: UUID? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var editorRequest: JournalEditorRequest?
    @State private var openSwipeRowID: UUID?
    @State private var scrollPosition = ScrollPosition(edge: .top)
    /// Pushed entry details, by id. The keyword sheet can push another entry on top.
    @State private var detailPath: [UUID] = []

    private var isRegular: Bool { horizontalSizeClass == .regular }

    private func openEntry(_ entry: Journal) {
        if let onOpenEntry {
            onOpenEntry(entry)
        } else {
            detailPath.append(entry.id)
        }
    }

    @ViewBuilder
    private func detailDestination(_ id: UUID) -> some View {
        if let entry = viewModel.entries.first(where: { $0.id == id }) {
            JournalDetailView(
                journal: entry,
                onOpenEntry: { detailPath.append($0.id) },
                onEdit: onEditEntry,
                onDelete: { deleted in
                    // Back to the list first, then the undo toast (Part A 3.8).
                    detailPath.removeAll()
                    delete(deleted)
                }
            )
        }
    }
    /// The tablet draws its own title row, and search takes over the top of the phone screen.
    private var isNavigationBarHidden: Bool { isRegular || viewModel.isSearchActive }

    var body: some View {
        NavigationStack(path: $detailPath) {
            content
                .background(Color.CANVAS)
                .navigationTitle("기록")
                .navigationDestination(for: UUID.self) { id in
                    detailDestination(id)
                }
                .toolbar {
                    if !isNavigationBarHidden {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                openEditor(on: viewModel.today)
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(Color.TEXT_PRIMARY)
                            }
                            .accessibilityLabel("새 일기")
                        }
                    }
                }
                .toolbar(isNavigationBarHidden ? .hidden : .visible, for: .navigationBar)
        }
        .overlay(alignment: .bottom) { undoToast }
        .onAppear { openSwipeRowID = initialOpenSwipeRowID }
        .animation(.easeInOut(duration: 0.2), value: viewModel.pendingDeletion?.journal.id)
        .fullScreenCover(item: $editorRequest) { request in
            JournalEditorView(
                initialDate: request.day,
                onClose: { editorRequest = nil }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.entries.isEmpty {
            emptyContent
        } else if isRegular {
            tabletContent
        } else {
            phoneContent
        }
    }

    private func openEditor(on day: Date) {
        editorRequest = JournalEditorRequest(day: day)
    }

    private func delete(_ entry: Journal) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.delete(entry)
    }

    // MARK: - Empty

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isRegular {
                tabletHeader
                    .padding(.leading, JournalLayout.tabletGutter)
                    .padding(.trailing, JournalLayout.tabletHeaderTrailing)
            }

            JournalSearchField(query: $viewModel.searchQuery, isActive: $viewModel.isSearchActive, isEnabled: false)
                .padding(.horizontal, isRegular ? JournalLayout.tabletGutter : JournalLayout.phoneGutter)
                .padding(.top, 8)

            JournalEmptyStateView { openEditor(on: viewModel.today) }
        }
    }

    // MARK: - Phone

    private var phoneContent: some View {
        let keywordStages = viewModel.keywordStages
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                searchField(height: 40, cornerRadius: 12)
                    .padding(.horizontal, JournalLayout.phoneGutter)
                    .padding(.top, 4)

                if viewModel.isSearchActive {
                    searchContent(keywordStages: keywordStages)
                        .padding(.top, 12)
                } else {
                    JournalModeToggle(mode: $viewModel.viewMode, height: 36)
                        .padding(.horizontal, JournalLayout.phoneGutter)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    switch viewModel.viewMode {
                    case .list:
                        phoneListSections(keywordStages: keywordStages)
                    case .calendar:
                        JournalCalendarSection(
                            viewModel: viewModel,
                            keywordStages: keywordStages,
                            onOpenEntry: openEntry,
                            onWrite: openEditor(on:)
                        )
                        .padding(.horizontal, JournalLayout.phoneGutter)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .scrollPosition($scrollPosition)
        .scrollDismissesKeyboard(.immediately)
        .onScrollPhaseChange { _, phase in
            if phase == .interacting { openSwipeRowID = nil }
        }
        .onChange(of: viewModel.scrollToTopSignal) {
            // The top edge is measured against the collapsed bar, so aim past it to expand the Large Title.
            withAnimation { scrollPosition.scrollTo(y: JournalLayout.largeTitleExpandedOffset) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
        .animation(.easeInOut(duration: 0.2), value: viewModel.entries.map(\.id))
    }

    private func searchField(height: CGFloat, cornerRadius: CGFloat) -> some View {
        JournalSearchField(
            query: $viewModel.searchQuery,
            isActive: $viewModel.isSearchActive,
            isEnabled: true,
            height: height,
            cornerRadius: cornerRadius,
            onCancel: { viewModel.deactivateSearch() },
            onSubmit: { viewModel.commitRecentSearch() }
        )
    }

    @ViewBuilder
    private func phoneListSections(keywordStages: [String: Int]) -> some View {
        ForEach(viewModel.sortedByMonth, id: \.month) { section in
            Section {
                ForEach(section.entries) { entry in
                    VStack(spacing: 0) {
                        JournalSwipeRow(
                            id: entry.id,
                            openRowID: $openSwipeRowID,
                            onDelete: { delete(entry) }
                        ) {
                            JournalEntryRow(entry: entry, keywordStages: keywordStages)
                                .padding(.horizontal, JournalLayout.phoneGutter)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture { tapRow(entry) }
                                .contextMenu { entryMenu(entry) } preview: {
                                    JournalEntryRow(entry: entry, keywordStages: keywordStages)
                                        .padding(16)
                                        .frame(width: 360)
                                        .background(Color.CANVAS)
                                }
                        }
                        JournalHairline()
                    }
                    .transition(.opacity)
                }
            } header: {
                JournalMonthHeader(month: section.month, count: section.entries.count)
            }
        }
    }

    /// While a row is swiped open, the next tap only closes it.
    private func tapRow(_ entry: Journal) {
        if openSwipeRowID != nil {
            openSwipeRowID = nil
        } else {
            openEntry(entry)
        }
    }

    @ViewBuilder
    private func entryMenu(_ entry: Journal) -> some View {
        Button {
            onEditEntry(entry)
        } label: {
            Label("편집", systemImage: "pencil")
        }
        ShareLink(item: "\(entry.displayTitle)\n\n\(entry.body)") {
            Label("공유", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive) {
            delete(entry)
        } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    private func searchContent(keywordStages: [String: Int]) -> some View {
        JournalSearchContent(
            viewModel: viewModel,
            keywordStages: keywordStages,
            onOpenEntry: openEntry,
            onOpenKeyword: onOpenKeyword
        )
    }

    // MARK: - Tablet

    private var tabletContent: some View {
        let keywordStages = viewModel.keywordStages
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                tabletHeader
                    .padding(.trailing, JournalLayout.tabletHeaderTrailing - JournalLayout.tabletTrailing)
                    .padding(.bottom, -8)

                HStack(spacing: 12) {
                    searchField(height: 44, cornerRadius: 22)
                    if !viewModel.isSearchActive {
                        JournalModeToggle(mode: $viewModel.viewMode, height: 44)
                            .frame(width: 158)
                    }
                }

                if viewModel.isSearchActive {
                    searchContent(keywordStages: keywordStages)
                } else {
                    switch viewModel.viewMode {
                    case .list:
                        tabletList(keywordStages: keywordStages)
                    case .calendar:
                        JournalTabletCalendar(
                            viewModel: viewModel,
                            keywordStages: keywordStages,
                            onOpenEntry: openEntry,
                            onWrite: openEditor(on:)
                        )
                        .padding(.top, -12)
                    }
                }
            }
            .padding(.leading, JournalLayout.tabletGutter)
            .padding(.trailing, JournalLayout.tabletTrailing)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollPosition($scrollPosition)
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: viewModel.scrollToTopSignal) {
            withAnimation { scrollPosition.scrollTo(edge: .top) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
    }

    private var tabletHeader: some View {
        HStack(alignment: .center) {
            Text("기록")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Spacer()
            Button {
                openEditor(on: viewModel.today)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.SURFACE)
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("새 일기")
        }
        .padding(.top, 16)
    }

    private func tabletList(keywordStages: [String: Int]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
        return VStack(alignment: .leading, spacing: 24) {
            ForEach(viewModel.sortedByMonth, id: \.month) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(JournalDateText.yearMonth(section.month)) · \(section.entries.count)편")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.TEXT_SECONDARY)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(section.entries) { entry in
                            JournalEntryRow(
                                entry: entry,
                                keywordStages: keywordStages,
                                thumbnailSize: 96,
                                showsThumbnailGlyph: false,
                                chipTextColor: .TEXT_SECONDARY
                            )
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 137, alignment: .topLeading)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.SURFACE))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1))
                            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .onTapGesture { openEntry(entry) }
                            .contextMenu { entryMenu(entry) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Undo toast

    @ViewBuilder
    private var undoToast: some View {
        if let deletion = viewModel.pendingDeletion {
            HStack(spacing: 12) {
                Text("‘\(deletion.journal.displayTitle)’을 삭제했어요")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button("실행 취소") { viewModel.undoDeletion() }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.TOAST_ACTION)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(Capsule().fill(Color.TOAST_BACKGROUND))
            .padding(.horizontal, JournalLayout.phoneGutter)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct JournalHairline: View {
    var body: some View {
        Rectangle().fill(Color.HAIRLINE).frame(height: 1)
    }
}

// MARK: - Mode toggle

private struct JournalModeToggle: View {
    @Binding var mode: JournalViewMode
    let height: CGFloat

    @Namespace private var selection

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JournalViewMode.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = option }
                } label: {
                    Text(option.title)
                        .font(.system(size: 15, weight: mode == option ? .bold : .regular))
                        .foregroundStyle(mode == option ? Color.TEXT_PRIMARY : Color.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if mode == option {
                                Capsule()
                                    .fill(Color.SURFACE)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "selection", in: selection)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == option ? .isSelected : [])
            }
        }
        .padding(2)
        .frame(height: height)
        .background(Capsule().fill(Color.SUNKEN))
    }
}

// MARK: - Swipe to delete

/// A row that reveals a full-height delete block. Swiping past 60% of the row deletes it right away.
private struct JournalSwipeRow<Content: View>: View {
    let id: UUID
    @Binding var openRowID: UUID?
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool?
    @State private var rowWidth: CGFloat = 0

    private var restingOffset: CGFloat {
        openRowID == id ? -JournalLayout.swipeActionWidth : 0
    }

    private var offset: CGFloat { min(0, restingOffset + dragOffset) }

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                Button(action: deleteRow) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                        Text("삭제")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: max(JournalLayout.swipeActionWidth, -offset))
                    .frame(maxHeight: .infinity)
                    .background(Color.DANGER)
                }
                .buttonStyle(.plain)
            }

            content
                .background(Color.CANVAS)
                .offset(x: offset)
        }
        .clipped()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
        .simultaneousGesture(swipeGesture)
        .accessibilityAction(named: "삭제", deleteRow)
    }

    /// Clears the open state first so an undo brings the row back closed.
    private func deleteRow() {
        openRowID = nil
        onDelete()
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                defer { isHorizontalDrag = nil }
                guard isHorizontalDrag == true else { return }
                finishSwipe(at: restingOffset + value.translation.width)
            }
    }

    private func finishSwipe(at position: CGFloat) {
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = 0
            if position < -rowWidth * 0.6 {
                deleteRow()
            } else {
                openRowID = position < -JournalLayout.swipeActionWidth / 2 ? id : (openRowID == id ? nil : openRowID)
            }
        }
    }
}

// MARK: - Search field

private struct JournalSearchField: View {
    @Binding var query: String
    @Binding var isActive: Bool
    let isEnabled: Bool
    var height: CGFloat = 40
    var cornerRadius: CGFloat = 12
    var onCancel: () -> Void = {}
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)

                TextField("제목, 본문, 키워드 검색", text: $query)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.TEXT_TERTIARY)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("지우기")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Color.SUNKEN))
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                }
            }
            .opacity(isEnabled ? 1 : 0.6)
            .disabled(!isEnabled)
            .onChange(of: isFocused) { _, focused in
                if focused { isActive = true }
            }

            if isActive {
                Button("취소") {
                    isFocused = false
                    onCancel()
                }
                .font(.system(size: 16))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - List parts

private struct JournalMonthHeader: View {
    let month: Date
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(JournalDateText.yearMonth(month))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text("\(count)편")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .padding(.horizontal, JournalLayout.phoneGutter)
            JournalHairline()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.CANVAS)
    }
}

// MARK: - Previews

@MainActor
private func journalPreviewModel(
    mode: JournalViewMode = .list,
    entries: [Journal] = Journal.listSamples
) -> JournalViewModel {
    let calendar = Calendar(identifier: .gregorian)
    let october = { (day: Int) in calendar.date(from: DateComponents(year: 2026, month: 10, day: day))! }
    // An entry in an earlier month keeps the "previous month" arrow active, as in the design.
    let september = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15))!
    let journals = mode == .calendar ? entries + [Journal(day: september, createdAt: september, title: "9월의 기록")] : entries
    let viewModel = JournalViewModel(repository: InMemoryJournalRepository(journals: journals))
    viewModel.today = october(30)
    viewModel.viewMode = mode
    viewModel.displayedMonth = october(1)
    viewModel.selectedDate = october(27)
    viewModel.keywordStageOverride = ["휴식": 0, "경청": 1, "솔직함": 2, "꾸준함": 3, "감사": 4]
    return viewModel
}

@MainActor
private func journalSwipePreviewModel() -> JournalViewModel {
    let deleted = Journal(title: "퇴근길 산책")
    let viewModel = journalPreviewModel(entries: Journal.listSamples + [deleted])
    viewModel.delete(deleted, autoCommit: false)
    return viewModel
}

@MainActor
private func journalSearchPreviewModel() -> JournalViewModel {
    let viewModel = journalPreviewModel(entries: Journal.searchSamples)
    viewModel.isSearchActive = true
    viewModel.applySearch("경청")
    return viewModel
}

/// `JournalView` takes the view model directly; the detail and editor it opens read it from the environment.
private func journalPreview(_ viewModel: JournalViewModel, initialOpenSwipeRowID: UUID? = nil) -> some View {
    JournalView(viewModel: viewModel, initialOpenSwipeRowID: initialOpenSwipeRowID)
        .environment(viewModel)
}

private extension View {
    func journalTabletPreview() -> some View {
        environment(\.horizontalSizeClass, .regular)
    }
}

#Preview("listSegment") {
    journalPreview(journalPreviewModel())
}

#Preview("calendarSegment") {
    journalPreview(journalPreviewModel(mode: .calendar, entries: Journal.calendarSamples))
}

#Preview("emptyJournals") {
    journalPreview(journalPreviewModel(entries: []))
}

#Preview("listSwipe") {
    let viewModel = journalSwipePreviewModel()
    journalPreview(viewModel, initialOpenSwipeRowID: viewModel.entries[1].id)
}

#Preview("searching") {
    journalPreview(journalSearchPreviewModel())
}

#Preview("tablet-listSegment", traits: .fixedLayout(width: 1194, height: 834)) {
    journalPreview(journalPreviewModel())
        .journalTabletPreview()
}

#Preview("tablet-calendarSegment", traits: .fixedLayout(width: 1194, height: 834)) {
    journalPreview(journalPreviewModel(mode: .calendar))
        .journalTabletPreview()
}
