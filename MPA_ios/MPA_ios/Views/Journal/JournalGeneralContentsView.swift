//
//  JournalGeneralContentsView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/26.
//

import SwiftUI

struct JournalGeneralContentsView: View {
    @Bindable var viewModel: JournalViewModel
    
    @Binding var scrollPosition: ScrollPosition
    @Binding var openSwipeRowID: UUID?
    
    var onOpenEntry: (Journal) -> Void
    var onOpenEditor: (Date) -> Void
    var onOpenKeyword: (String) -> Void
    
    var body: some View {
        let keywordStages = viewModel.keywordStages
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                JournalSearchField(
                    query: $viewModel.searchQuery,
                    isActive: $viewModel.isSearchActive,
                    isEnabled: true,
                    height: 40,
                    cornerRadius: 12,
                    onCancel: { viewModel.deactivateSearch() },
                    onSubmit: { viewModel.commitRecentSearch() }
                )
                .padding(.horizontal, JournalLayout.phoneGutter)
                .padding(.top, 4)

                if viewModel.isSearchActive {
                    JournalSearchContent(
                        viewModel: viewModel,
                        keywordStages: keywordStages,
                        onOpenEntry: onOpenEntry,
                        onOpenKeyword: onOpenKeyword
                    )
                    .padding(.top, 12)
                } else {
                    JournalModeToggle(mode: $viewModel.viewMode, height: 36)
                        .padding(.horizontal, JournalLayout.phoneGutter)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    switch viewModel.viewMode {
                    case .list:
                        ForEach(viewModel.sortedByMonth, id: \.month) { section in
                            JournalListSection(
                                viewModel: viewModel,
                                openSwipeRowID: $openSwipeRowID,
                                section: section,
                                keywordStages: keywordStages,
                                onOpenEntry: onOpenEntry
                            )
                        }
                    case .calendar:
                        JournalCalendarSection(
                            viewModel: viewModel,
                            keywordStages: keywordStages,
                            onOpenEntry: onOpenEntry,
                            onWrite: onOpenEditor
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
}

struct JournalSwipeRow<Content: View>: View {
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

struct JournalMonthHeader: View {
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

struct JournalHairline: View {
    var body: some View {
        Rectangle().fill(Color.HAIRLINE).frame(height: 1)
    }
}
