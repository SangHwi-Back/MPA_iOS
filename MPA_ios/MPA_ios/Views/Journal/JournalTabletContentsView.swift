//
//  JournalTabletContents.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/26.
//

import SwiftUI

struct JournalTabletContents: View {
    @Bindable var viewModel: JournalViewModel
    
    @Binding var scrollPosition: ScrollPosition
    
    var onOpenEntry: (Journal) -> Void
    var onOpenEditor: (Date) -> Void
    var onOpenKeyword: (String) -> Void
    
    var body: some View {
        let keywordStages = viewModel.keywordStages
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                JournalContentsTabletHeader(
                    viewModel: viewModel,
                    onOpenEditor: onOpenEditor
                )
                .padding(.trailing, JournalLayout.tabletHeaderTrailing - JournalLayout.tabletTrailing)
                .padding(.bottom, -8)

                HStack(spacing: 12) {
                    JournalSearchField(
                        query: $viewModel.searchQuery,
                        isActive: $viewModel.isSearchActive,
                        isEnabled: true,
                        height: 44,
                        cornerRadius: 22,
                        onCancel: { viewModel.deactivateSearch() },
                        onSubmit: { viewModel.commitRecentSearch() }
                    )
                    
                    if !viewModel.isSearchActive {
                        JournalModeToggle(mode: $viewModel.viewMode, height: 44)
                            .frame(width: 158)
                    }
                }

                if viewModel.isSearchActive {
                    JournalSearchContent(
                        viewModel: viewModel,
                        keywordStages: keywordStages,
                        onOpenEntry: onOpenEntry,
                        onOpenKeyword: onOpenKeyword
                    )
                } else {
                    switch viewModel.viewMode {
                    case .list:
                        tabletList(keywordStages: keywordStages)
                    case .calendar:
                        JournalTabletCalendar(
                            viewModel: viewModel,
                            keywordStages: keywordStages,
                            onOpenEntry: onOpenEntry,
                            onWrite: onOpenEditor
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
                            .onTapGesture {
                                onOpenEntry(entry)
                            }
                            .contextMenu {
                                JournalContentsEntryMenu(viewModel: viewModel, entry: entry)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct JournalContentsTabletHeader: View {
    @Bindable var viewModel: JournalViewModel
    
    var onOpenEditor: (Date) -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Text("기록")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Spacer()
            Button {
                onOpenEditor(viewModel.today)
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
}

struct JournalContentsEntryMenu: View {
    @Environment(\.editorRequest) private var showFullscreenEntryRequest
    
    @Bindable var viewModel: JournalViewModel
    
    var entry: Journal
    
    var body: some View {
        Button {
            showFullscreenEntryRequest.wrappedValue = JournalEditorRequest(day: entry.day)
        } label: {
            Label("편집", systemImage: "pencil")
        }
        ShareLink(item: "\(entry.displayTitle)\n\n\(entry.body)") {
            Label("공유", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.delete(entry)
        } label: {
            Label("삭제", systemImage: "trash")
        }
    }
}
