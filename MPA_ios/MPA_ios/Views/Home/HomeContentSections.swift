//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  HomeContentSections.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/12/26.
//


import SwiftUI

/// Phone sections, chosen by the state matrix.
struct HomeContentSections: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    let onConnectKey: () -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        switch homeViewModel.layout {
        case .firstRun:
            HomeContentFirstRun(onWrite: onWrite)
        case .early:
            HomeContentAdviceCard(onOpenEntry: onOpenEntry, onConnectKey: onConnectKey)
            HomeContentTodayCard(onWrite: onWrite, onOpenEntry: onOpenEntry)
            HomePrincipleProgressSection(entryCount: homeViewModel.entries.count)
                .padding(.top, 16)
        case .full:
            HomeContentAdviceCard(onOpenEntry: onOpenEntry, onConnectKey: onConnectKey)
            HomeContentTodayCard(onWrite: onWrite, onOpenEntry: onOpenEntry)
            HomeContentPrinciples(onOpenEntry: onOpenEntry, onSelectTab: onSelectTab)
                .padding(.top, 24)
            if homeViewModel.showsWeeklySummary {
                HomeContentWeeklySummary(isAlwaysExpanded: false, onOpenEntry: onOpenEntry)
                    .padding(.top, 8)
            }
        case .diary:
            HomeContentDiaryTodayCard(onWrite: onWrite, onOpenEntry: onOpenEntry)
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
    
    private func selectWeekDay(_ day: HomeWeekDay) {
        if let entry = HomeViewModel.newestFirst(homeViewModel.entries).first(where: { Calendar.current.isDate($0.day, inSameDayAs: day.date) }) {
            onOpenEntry(entry)
        } else {
            onWrite(day.date, nil)
        }
    }
}

private struct HomeContentFirstRun: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        HomeFirstRunSection(
            privacyLine: homeViewModel.privacyLine,
            onQuestion: { onWrite(nil, $0) }
        )
    }
}

private struct HomeContentPrinciples: View {
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        HomePrinciplesSection(
            principles: homeViewModel.principles,
            entryCount: homeViewModel.entries.count,
            onSeeAll: { onSelectTab(.principles) },
            onOpenEntry: onOpenEntry
        )
    }
}

/// 일기 앱 모드: today's entry if there is one, otherwise the plain write card.
private struct HomeContentDiaryTodayCard: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        if let entry = homeViewModel.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomeDiaryTodayCard { onWrite(nil, nil) }
        }
    }
}
