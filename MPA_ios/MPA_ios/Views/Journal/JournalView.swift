//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

enum JournalViewMode: String, CaseIterable {
    case list
    case calendar

    var title: String {
        switch self {
        case .list:     return "리스트"
        case .calendar: return "캘린더"
        }
    }
}

private extension Color {
    static let DISABLED_ARROW = Color.mpa("#C9C2B8", dark: "#4A4640")
    static let PHOTO_PLACEHOLDER = Color.mpa("#DCD5C9", dark: "#2E2B28")
    static let TOAST_BACKGROUND = Color(hex: "#363432")
    static let TOAST_ACTION = Color(hex: "#AEB8F0")
    static let SWIPE_DELETE = Color.mpa("#DA3A2B", dark: DarkColorHex.danger)
    static let principleScale: [Color] = [.PRINCIPLE1, .PRINCIPLE2, .PRINCIPLE3, .PRINCIPLE4, .PRINCIPLE5]
}

private enum JournalLayout {
    static let phoneGutter: CGFloat = 20
    static let tabletGutter: CGFloat = 38
    /// Leaves room for the floating tab rail on the right.
    static let tabletTrailing: CGFloat = 112
    static let tabletHeaderTrailing: CGFloat = 20
    static let swipeActionWidth: CGFloat = 96
    static let largeTitleExpandedOffset: CGFloat = -100
    static let keywordRowHeight: CGFloat = 28
}

private enum JournalDateText {
    static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    static func day(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    static func weekday(_ date: Date) -> String {
        weekdays[Calendar.current.component(.weekday, from: date) - 1]
    }

    static func month(_ date: Date) -> String {
        "\(Calendar.current.component(.month, from: date))월"
    }

    static func yearMonth(_ date: Date) -> String {
        "\(Calendar.current.component(.year, from: date))년 \(month(date))"
    }

    static func selectedDay(_ date: Date) -> String {
        "\(month(date)) \(day(date))일 \(weekday(date))요일"
    }
}

private extension Journal {
    /// Maximum characters of body that fit in the two preview lines.
    static let snippetVisibleLength = 40

    /// The preview text, cut to the sentence containing the match when the match is past the two visible lines.
    func searchSnippet(for query: String) -> String {
        let text = previewText
        guard let match = text.range(of: query, options: .caseInsensitive),
              text.distance(from: text.startIndex, to: match.lowerBound) > Self.snippetVisibleLength else {
            return text
        }
        let sentenceStart = text[..<match.lowerBound].range(of: ". ", options: .backwards)?.upperBound
        return "…" + text[(sentenceStart ?? match.lowerBound)...]
    }

    /// Analysis has not finished, so the chip area stays blank instead of collapsing.
    var reservesKeywordSpace: Bool {
        switch analysisState {
        case .notAnalyzed, .analyzing: return true
        case .analyzed, .failed, .unavailable: return false
        }
    }

    var showsKeywords: Bool {
        if case .analyzed = analysisState { return true }
        return false
    }
}

private struct JournalEditorRequest: Identifiable {
    let id = UUID()
    let day: Date
}

struct JournalView: View {
    @ObservedObject var viewModel: JournalViewModel
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
                journalViewModel: viewModel,
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
                viewModel: viewModel,
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
                            .journalCard()
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

private extension View {
    func journalCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.SURFACE)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1)
        )
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
                    .background(Color.SWIPE_DELETE)
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

private struct JournalKeywordChip: View {
    let name: String
    let stage: Int
    var isEmphasized: Bool = false
    var textColor: Color = .AI_ACCENT

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.principleScale[min(stage, Color.principleScale.count - 1)])
                .frame(width: 7, height: 7)
            Text(name)
                .font(.system(size: 13, weight: isEmphasized ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Capsule().fill(Color.AI_TINT))
    }
}

private struct JournalThumbnail: View {
    let photo: JournalPhoto
    let extraCount: Int
    let size: CGFloat
    let showsGlyph: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.PHOTO_PLACEHOLDER)
            .overlay {
                if showsGlyph {
                    Image("image_placeholder_glyph")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if extraCount > 0 {
                    Text("+\(extraCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.black.opacity(0.55)))
                        .padding(4)
                }
            }
            .frame(width: size, height: size)
    }
}

/// One journal item. Used by the list, the calendar's selected day, and search results.
private struct JournalEntryRow: View {
    enum DateCaption { case weekday, month }

    let entry: Journal
    var dateCaption: DateCaption = .weekday
    var highlight: String? = nil
    var bodyText: String? = nil
    let keywordStages: [String: Int]
    var thumbnailSize: CGFloat = 60
    var showsThumbnailGlyph: Bool = true
    var chipTextColor: Color = .AI_ACCENT

    private var chips: [JournalKeyword] {
        Array(entry.visibleKeywords.prefix(Journal.maxKeywordsInList))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(JournalDateText.day(entry.day))
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text(dateCaption == .weekday ? JournalDateText.weekday(entry.day) : JournalDateText.month(entry.day))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(highlighted(entry.displayTitle))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineLimit(1)

                Text(highlighted(bodyText ?? entry.previewText))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                keywordRow
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let photo = entry.thumbnail {
                JournalThumbnail(photo: photo, extraCount: entry.photos.count - 1, size: thumbnailSize, showsGlyph: showsThumbnailGlyph)
            }
        }
    }

    @ViewBuilder
    private var keywordRow: some View {
        if entry.showsKeywords, !chips.isEmpty {
            HStack(spacing: 6) {
                ForEach(chips, id: \.name) { keyword in
                    JournalKeywordChip(
                        name: keyword.name,
                        stage: keywordStages[keyword.name] ?? 0,
                        isEmphasized: keyword.name == highlight,
                        textColor: chipTextColor
                    )
                }
            }
        } else if entry.reservesKeywordSpace {
            Color.clear.frame(height: JournalLayout.keywordRowHeight)
        }
    }

    private func highlighted(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        guard let highlight, !highlight.isEmpty else { return result }
        var searchStart = result.startIndex
        while searchStart < result.endIndex,
              let match = result[searchStart...].range(of: highlight, options: .caseInsensitive) {
            result[match].swiftUI.backgroundColor = .HIGHLIGHT_SEARCH
            searchStart = match.upperBound
        }
        return result
    }
}

// MARK: - Search content

private struct JournalSearchContent: View {
    @ObservedObject var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onOpenKeyword: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.searchQuery.isEmpty {
                recentSearches
            } else if !viewModel.appliedSearchQuery.isEmpty {
                if viewModel.hasSearchResults {
                    keywordSuggestions
                    results
                } else {
                    noResults
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .padding(.horizontal, JournalLayout.phoneGutter)
    }

    @ViewBuilder
    private var recentSearches: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("최근 검색")
                ForEach(viewModel.recentSearches, id: \.self) { query in
                    HStack {
                        Button {
                            viewModel.applySearch(query)
                        } label: {
                            Text(query)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.TEXT_PRIMARY)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.removeRecentSearch(query)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.TEXT_TERTIARY)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(query) 삭제")
                    }
                    .padding(.horizontal, JournalLayout.phoneGutter)
                }
            }
        }
    }

    @ViewBuilder
    private var keywordSuggestions: some View {
        let suggestions = viewModel.searchKeywordMatches
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("키워드")
                ForEach(suggestions) { suggestion in
                    Button {
                        onOpenKeyword(suggestion.name)
                    } label: {
                        keywordCard(suggestion)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, JournalLayout.phoneGutter)
                }
            }
        }
    }

    private func keywordCard(_ suggestion: JournalKeywordSuggestion) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.principleScale[min(keywordStages[suggestion.name] ?? 0, Color.principleScale.count - 1)])
                .frame(width: 24, height: 24)
            Text("\(Text(suggestion.name).bold()) 키워드로 모아 보기")
                .font(.system(size: 16))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("\(suggestion.count)편")
                .font(.system(size: 14))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.TEXT_SECONDARY)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.AI_TINT))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var results: some View {
        let matches = viewModel.searchTitleBodyMatches
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("제목·본문 \(matches.count)편")
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Rectangle().fill(Color.HAIRLINE).frame(height: 1)
                        }
                        JournalEntryRow(
                            entry: entry,
                            dateCaption: .month,
                            highlight: viewModel.appliedSearchQuery,
                            bodyText: entry.searchSnippet(for: viewModel.appliedSearchQuery),
                            keywordStages: keywordStages
                        )
                        .padding(.horizontal, JournalLayout.phoneGutter)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { onOpenEntry(entry) }
                    }
                }
            }
        }
    }

    private var noResults: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.TEXT_TERTIARY)
            Text("‘\(viewModel.appliedSearchQuery)’에 맞는 기록이 없어요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}

// MARK: - Calendar (phone)

private struct JournalMonthPicker: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var isShowingPicker = false

    private var pickerSelection: Binding<Date> {
        Binding(get: { viewModel.displayedMonth }, set: { viewModel.showMonth($0) })
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                isShowingPicker = true
            } label: {
                Text(JournalDateText.yearMonth(viewModel.displayedMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingPicker) {
                DatePicker(
                    "연·월 선택",
                    selection: pickerSelection,
                    in: viewModel.earliestMonth...viewModel.today,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .presentationCompactAdaptation(.popover)
            }

            Spacer(minLength: 0)

            arrow("chevron.left", label: "이전 달", isEnabled: viewModel.canGoToPreviousMonth) {
                viewModel.changeMonth(by: -1)
            }
            arrow("chevron.right", label: "다음 달", isEnabled: viewModel.canGoToNextMonth) {
                viewModel.changeMonth(by: 1)
            }
        }
    }

    private func arrow(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.BRAND_PRIMARY : Color.DISABLED_ARROW)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

private extension View {
    /// Moves between months with a horizontal swipe.
    func monthSwipe(_ viewModel: JournalViewModel) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 2 else { return }
                viewModel.changeMonth(by: value.translation.width < 0 ? 1 : -1)
            }
        )
    }
}

private struct JournalCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let hasEntry: Bool

    private var numberColor: Color {
        if isSelected { return .BRAND_ON_PRIMARY }
        if isFuture { return .DISABLED_ARROW }
        return isToday ? .BRAND_PRIMARY : .TEXT_PRIMARY
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(JournalDateText.day(date))
                .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                .foregroundStyle(numberColor)
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle().fill(Color.BRAND_PRIMARY)
                    } else if isToday {
                        Circle().stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                    }
                }
            Circle()
                .fill(hasEntry ? Color.BRAND_PRIMARY : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .contentShape(Rectangle())
    }
}

private func journalDayAccessibilityLabel(_ date: Date, hasEntry: Bool, isSelected: Bool) -> String {
    var parts = ["\(JournalDateText.month(date)) \(JournalDateText.day(date))일"]
    if hasEntry { parts.append("일기 있음") }
    if isSelected { parts.append("선택됨") }
    return parts.joined(separator: ", ")
}

private struct JournalDayEmptyView: View {
    let onWrite: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("이 날의 기록이 없어요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Button("이 날짜로 쓰기", action: onWrite)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .buttonStyle(.plain)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

private struct JournalMonthEmptyView: View {
    var body: some View {
        Text("이 달의 기록이 없어요")
            .font(.system(size: 15))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

private struct JournalCalendarSection: View {
    @ObservedObject var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onWrite: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let entriesByDay = viewModel.entriesByDay
        VStack(alignment: .leading, spacing: 0) {
            JournalMonthPicker(viewModel: viewModel)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.weekdayHeaders, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(height: 30)
                }
                ForEach(Array(viewModel.calendarGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date, hasEntry: entriesByDay[date]?.isEmpty == false)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
            .monthSwipe(viewModel)

            Rectangle()
                .fill(Color.HAIRLINE)
                .frame(height: 1)
                .padding(.top, 8)

            dayContent
                .padding(.top, 14)
        }
    }

    private func dayCell(_ date: Date, hasEntry: Bool) -> some View {
        let isSelected = date == viewModel.selectedDate
        let isFuture = viewModel.isFuture(date)
        return Button {
            if let entry = viewModel.selectDay(date) { onOpenEntry(entry) }
        } label: {
            JournalCalendarDayCell(
                date: date,
                isSelected: isSelected,
                isToday: date == viewModel.today,
                isFuture: isFuture,
                hasEntry: hasEntry
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(journalDayAccessibilityLabel(date, hasEntry: hasEntry, isSelected: isSelected))
    }

    @ViewBuilder
    private var dayContent: some View {
        if viewModel.totalEntriesForMonth == 0 {
            JournalMonthEmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(JournalDateText.selectedDay(viewModel.selectedDate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.TEXT_SECONDARY)

                if viewModel.selectedDayEntries.isEmpty {
                    JournalDayEmptyView { onWrite(viewModel.selectedDate) }
                } else {
                    ForEach(viewModel.selectedDayEntries) { entry in
                        JournalEntryRow(entry: entry, keywordStages: keywordStages)
                            .contentShape(Rectangle())
                            .onTapGesture { onOpenEntry(entry) }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar (tablet)

private struct JournalTabletCalendar: View {
    @ObservedObject var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onWrite: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            calendar
            selectedDayPanel.frame(width: 370)
        }
    }

    private var calendar: some View {
        let entriesByDay = viewModel.entriesByDay
        return VStack(alignment: .leading, spacing: 8) {
            JournalMonthPicker(viewModel: viewModel)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.weekdayHeaders, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .padding(.leading, 4)
                }
                ForEach(Array(viewModel.calendarGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date, entries: entriesByDay[date] ?? [])
                    } else {
                        Color.clear
                            .frame(height: 84)
                            .overlay(alignment: .top) { hairline }
                    }
                }
            }
            .monthSwipe(viewModel)
        }
        .frame(maxWidth: .infinity)
    }

    private var hairline: some View {
        Rectangle().fill(Color.HAIRLINE).frame(height: 1)
    }

    private func dayCell(_ date: Date, entries: [Journal]) -> some View {
        let isSelected = date == viewModel.selectedDate
        let isToday = date == viewModel.today
        let isFuture = viewModel.isFuture(date)
        return Button {
            if let entry = viewModel.selectDay(date) { onOpenEntry(entry) }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(JournalDateText.day(date))
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.BRAND_ON_PRIMARY : isFuture ? Color.DISABLED_ARROW : isToday ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)
                    .frame(width: 26, height: 26)
                    .background {
                        if isSelected {
                            Circle().fill(Color.BRAND_PRIMARY)
                        } else if isToday {
                            Circle().stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                        }
                    }
                if let entry = entries.first {
                    Text(entry.displayTitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.AI_TINT))
                }
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84, alignment: .topLeading)
            .background(isSelected ? Color.SUNKEN.opacity(0.7) : Color.clear)
            .overlay(alignment: .top) { hairline }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(journalDayAccessibilityLabel(date, hasEntry: !entries.isEmpty, isSelected: isSelected))
    }

    @ViewBuilder
    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(JournalDateText.selectedDay(viewModel.selectedDate))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)

            if viewModel.totalEntriesForMonth == 0 {
                JournalMonthEmptyView()
            } else if viewModel.selectedDayEntries.isEmpty {
                JournalDayEmptyView { onWrite(viewModel.selectedDate) }
            } else {
                ForEach(viewModel.selectedDayEntries) { entry in
                    entryCard(entry)
                }
            }
        }
        .padding(.top, 6)
    }

    private func entryCard(_ entry: Journal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.thumbnail != nil {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.PHOTO_PLACEHOLDER)
                    .frame(height: 144)
            }
            Text(entry.displayTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 8)
            Text(entry.previewText)
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_PRIMARY.opacity(0.8))
                .lineSpacing(6)
            if entry.showsKeywords {
                HStack(spacing: 6) {
                    ForEach(Array(entry.visibleKeywords.prefix(Journal.maxKeywordsInList)), id: \.name) { keyword in
                        JournalKeywordChip(
                            name: keyword.name,
                            stage: keywordStages[keyword.name] ?? 0,
                            textColor: .TEXT_SECONDARY
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .journalCard()
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onOpenEntry(entry) }
    }
}

// MARK: - Empty state

private struct JournalEmptyStateView: View {
    let onWriteFirst: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image("empty_journal")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 130)
                .accessibilityHidden(true)

            Text("아직 기록이 없어요")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 12)

            Text("첫 일기를 쓰면 여기에\n날짜별로 차곡차곡 모여요.")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Button(action: onWriteFirst) {
                HStack(spacing: 8) {
                    Image("edit")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("첫 일기 쓰기")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Color.BRAND_ON_PRIMARY)
                .padding(.horizontal, 26)
                .frame(height: 48)
                .background(Capsule().fill(Color.BRAND_PRIMARY))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - Previews

@MainActor
private func journalPreviewModel(
    mode: JournalViewMode = .list,
    entries: [Journal] = Journal.listSamples
) -> JournalViewModel {
    let viewModel = JournalViewModel()
    let calendar = Calendar(identifier: .gregorian)
    let october = { (day: Int) in calendar.date(from: DateComponents(year: 2026, month: 10, day: day))! }
    viewModel.today = october(30)
    viewModel.viewMode = mode
    viewModel.displayedMonth = october(1)
    viewModel.selectedDate = october(27)
    // An entry in an earlier month keeps the "previous month" arrow active, as in the design.
    let september = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15))!
    viewModel.entries = mode == .calendar ? entries + [Journal(day: september, title: "9월의 기록")] : entries
    viewModel.keywordStageOverride = ["휴식": 0, "경청": 1, "솔직함": 2, "꾸준함": 3, "감사": 4]
    return viewModel
}

@MainActor
private func journalSwipePreviewModel() -> JournalViewModel {
    let viewModel = journalPreviewModel()
    let deleted = Journal(title: "퇴근길 산책")
    viewModel.entries.append(deleted)
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

private extension View {
    func journalTabletPreview() -> some View {
        environment(\.horizontalSizeClass, .regular)
    }
}

#Preview("listSegment") {
    JournalView(viewModel: journalPreviewModel())
}

#Preview("calendarSegment") {
    JournalView(viewModel: journalPreviewModel(mode: .calendar, entries: Journal.calendarSamples))
}

#Preview("emptyJournals") {
    JournalView(viewModel: journalPreviewModel(entries: []))
}

#Preview("listSwipe") {
    let viewModel = journalSwipePreviewModel()
    JournalView(viewModel: viewModel, initialOpenSwipeRowID: viewModel.entries[1].id)
}

#Preview("searching") {
    JournalView(viewModel: journalSearchPreviewModel())
}

#Preview("tablet-listSegment", traits: .fixedLayout(width: 1194, height: 834)) {
    JournalView(viewModel: journalPreviewModel())
        .journalTabletPreview()
}

#Preview("tablet-calendarSegment", traits: .fixedLayout(width: 1194, height: 834)) {
    JournalView(viewModel: journalPreviewModel(mode: .calendar))
        .journalTabletPreview()
}
