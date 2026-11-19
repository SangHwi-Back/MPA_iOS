// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalCollectionView.swift
//  MPA_ios
//

import SwiftUI

/// Entries that carry one keyword (Part A 3.9 "키워드로 모아 보기"). No search, toggle or calendar:
/// only the month sections of the list view, with the same swipe delete.
struct JournalCollectionView: View {
    @Bindable var viewModel: JournalViewModel
    let keyword: String

    var onOpenEntry: (Journal) -> Void

    @State private var openSwipeRowID: UUID?
    /// Starts with this row swiped open. Used by previews.
    var initialOpenSwipeRowID: UUID? = nil

    var body: some View {
        let keywordStages = viewModel.keywordStages
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.sortedByMonth(keyword: keyword), id: \.month) { section in
                    JournalListSection(
                        viewModel: viewModel,
                        openSwipeRowID: $openSwipeRowID,
                        section: section,
                        keywordStages: keywordStages,
                        onOpenEntry: onOpenEntry
                    )
                }
            }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .interacting { openSwipeRowID = nil }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.entries.map(\.id))
        .background(Color.CANVAS)
        .navigationTitle(keyword)
        .onAppear { openSwipeRowID = initialOpenSwipeRowID }
    }
}

// MARK: - Previews

@MainActor
private func collectionPreviewModel() -> JournalViewModel {
    let viewModel = JournalViewModel(repository: InMemoryJournalRepository(journals: Journal.listSamples))
    viewModel.keywordStageOverride = ["휴식": 0, "경청": 1, "솔직함": 2, "꾸준함": 3, "감사": 4]
    return viewModel
}

#Preview("listSwipe") {
    let viewModel = collectionPreviewModel()
    let swiped = viewModel.sortedByMonth(keyword: "경청").first?.entries.first?.id
    NavigationStack {
        JournalCollectionView(
            viewModel: viewModel,
            keyword: "경청",
            onOpenEntry: { _ in },
            initialOpenSwipeRowID: swiped
        )
    }
    .environment(viewModel)
}

#Preview("tablet-listSwipe", traits: .fixedLayout(width: 1194, height: 834)) {
    let viewModel = collectionPreviewModel()
    NavigationStack {
        JournalCollectionView(
            viewModel: viewModel,
            keyword: "경청",
            onOpenEntry: { _ in }
        )
    }
    .environment(viewModel)
    .environment(\.horizontalSizeClass, .regular)
}
