//
//  JournalContentView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/26.
//

import SwiftUI

struct JournalContentsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.editorRequest) private var showFullscreenEntryRequest
    
    @Bindable var viewModel: JournalViewModel
    
    @Binding private var openSwipeRowID: UUID?
    @Binding private var scrollPosition: ScrollPosition
    
    /// The tablet draws its own title row, and search takes over the top of the phone screen.
    private var isNavigationBarHidden: Bool { isRegular || viewModel.isSearchActive }
    /// Should show Tablet-contents or not
    private var isRegular: Bool { horizontalSizeClass == .regular }
    
    /// Opens the entry detail (Part B). When nil, the detail is pushed inside this tab.
    var onOpenEntry: ((Journal) -> Void)? = nil
    /// Opens the editor for an existing entry (Part C).
    var onEditEntry: (Journal) -> Void = { _ in }
    /// Opens the list of entries for a keyword.
    var onOpenKeyword: (String) -> Void = { _ in }
    var onOpenEditor: (Date) -> Void = { _ in }
    
    init(
        viewModel: JournalViewModel,
        openSwipeRowID: Binding<UUID?>,
        scrollPosition: Binding<ScrollPosition>,
        onOpenEntry: ((Journal) -> Void)? = nil,
        onEditEntry: @escaping (Journal) -> Void,
        onOpenKeyword: @escaping (String) -> Void,
        onOpenEditor: @escaping (Date) -> Void
    ) {
        self.viewModel = viewModel
        self._openSwipeRowID = openSwipeRowID
        self._scrollPosition = scrollPosition
        self.onOpenEntry = onOpenEntry
        self.onEditEntry = onEditEntry
        self.onOpenKeyword = onOpenKeyword
        self.onOpenEditor = onOpenEditor
    }
    
    var body: some View {
        Group {
            if viewModel.entries.isEmpty {
                JournalEmptyContentView(
                    viewModel: viewModel,
                    isRegular: isRegular,
                    onOpenEditor: onOpenEditor
                )
            } else if isRegular {
                JournalTabletContents(
                    viewModel: viewModel,
                    scrollPosition: $scrollPosition,
                    onOpenEntry: onOpenEntry ?? { _ in },
                    onOpenEditor: onOpenEditor,
                    onOpenKeyword: onOpenKeyword
                )
            } else {
                JournalGeneralContentsView(
                    viewModel: viewModel,
                    scrollPosition: $scrollPosition,
                    openSwipeRowID: $openSwipeRowID,
                    onOpenEntry: onOpenEntry ?? { _ in },
                    onOpenEditor: onOpenEditor,
                    onOpenKeyword: onOpenKeyword
                )
            }
        }
        .background(Color.CANVAS)
        .navigationTitle("기록")
        .toolbar {
            if !isNavigationBarHidden {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onOpenEditor(viewModel.today)
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
}

private struct JournalEmptyContentView: View {
    @Bindable var viewModel: JournalViewModel
    
    let isRegular: Bool
    
    var onOpenEditor: (Date) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isRegular {
                JournalContentsTabletHeader(
                    viewModel: viewModel,
                    onOpenEditor: onOpenEditor
                )
                .padding(.leading, JournalLayout.tabletGutter)
                .padding(.trailing, JournalLayout.tabletHeaderTrailing)
            }

            JournalSearchField(query: $viewModel.searchQuery, isActive: $viewModel.isSearchActive, isEnabled: false)
                .padding(.horizontal, isRegular ? JournalLayout.tabletGutter : JournalLayout.phoneGutter)
                .padding(.top, 8)

            JournalEmptyStateView { onOpenEditor(viewModel.today) }
        }
    }
}
