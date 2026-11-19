//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

struct JournalView: View {
    @Bindable var viewModel: JournalViewModel
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var editorRequest: JournalEditorRequest?
    @State private var openSwipeRowID: UUID?
    @State private var scrollPosition = ScrollPosition(edge: .top)
    /// Pushed entry details, by id. The keyword sheet can push another entry on top.
    @State private var detailPath: [JournalNavigationPath] = []
    
    /// Opens the entry detail (Part B). When nil, the detail is pushed inside this tab.
    var onOpenEntry: ((Journal) -> Void)? = nil
    
    /// Opens the list of entries for a keyword.
    var onOpenKeyword: (String) -> Void = { _ in }
    /// Starts with this row swiped open. Used by previews.
    var initialOpenSwipeRowID: UUID? = nil

    private var isRegular: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack(path: $detailPath) {
            JournalContentsView(
                viewModel: viewModel,
                openSwipeRowID: $openSwipeRowID,
                editorRequest: $editorRequest,
                scrollPosition: $scrollPosition,
                onEditEntry: onEditEntry,
                onOpenKeyword: onOpenKeyword,
                onOpenEditor: openEditor(on:)
            )
        }
        .overlay(alignment: .bottom) { undoToast }
        .animation(.easeInOut(duration: 0.2), value: viewModel.pendingDeletion?.journal.id)
        .navigationDestination(for: UUID.self) { id in
            if let entry = viewModel.entries.first(where: { $0.id == id }) {
                JournalDetailView(
                    journal: entry,
                    onOpenEntry: { detailPath.append(.detail($0)) },
                    onEdit: onEditEntry,
                    onDelete: { deleted in
                        // Back to the list first, then the undo toast (Part A 3.8).
                        detailPath.removeAll()
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.delete(deleted)
                    }
                )
            }
        }
        .onAppear { openSwipeRowID = initialOpenSwipeRowID }
        .fullScreenCover(item: $editorRequest) { request in
            JournalEditorView(
                initialDate: request.day,
                onClose: { editorRequest = nil }
            )
        }
    }
    
    private func openEntry(_ entry: Journal) {
        if let onOpenEntry {
            onOpenEntry(entry)
        } else {
            detailPath.append(.detail(entry))
        }
    }
    
    private func openEditor(on day: Date) {
        editorRequest = JournalEditorRequest(day: day)
    }
    
    /// Opens the editor for an existing entry (Part C).
    private func onEditEntry(_ entry: Journal) {
        detailPath.append(.editor(entry))
    }

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

// MARK: - List parts
enum JournalNavigationPath: Hashable {
    case detail(Journal)
    case editor(Journal)
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
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
