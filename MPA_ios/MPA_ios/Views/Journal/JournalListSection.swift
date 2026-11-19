//
//  JournalListSection.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/19/26.
//

import SwiftUI

struct JournalListSection: View {
    @Bindable var viewModel: JournalViewModel
    
    @Binding var openSwipeRowID: UUID?
    
    var section: (month: Date, entries: [Journal])
    var keywordStages: [String: Int]
    var onOpenEntry: (Journal) -> Void
    
    var body: some View {
        Section {
            ForEach(section.entries) { entry in
                VStack(spacing: 0) {
                    JournalSwipeRow(
                        id: entry.id,
                        openRowID: $openSwipeRowID,
                        onDelete: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.delete(entry)
                        }
                    ) {
                        JournalEntryRow(entry: entry, keywordStages: keywordStages)
                            .padding(.horizontal, JournalLayout.phoneGutter)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture { tapRow(entry) }
                            .contextMenu {
                                JournalContentsEntryMenu(viewModel: viewModel, entry: entry)
                            } preview: {
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
    
    /// While a row is swiped open, the next tap only closes it.
    func tapRow(_ entry: Journal) {
        if openSwipeRowID != nil {
            openSwipeRowID = nil
        } else {
            onOpenEntry(entry)
        }
    }
}
