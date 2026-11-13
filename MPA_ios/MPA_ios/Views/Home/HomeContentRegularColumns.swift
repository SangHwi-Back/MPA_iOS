//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  HomeContentRegularColumns.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/12/26.
//


import SwiftUI

/// Tablet: advice + 글감 on the left, principles + summary on the right.
struct HomeContentRegularColumns: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    let onSelectTab: (ContentTab) -> Void
    let onConnectKey: () -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack {
//            VStack(spacing: HomeLayoutMetrics.sectionSpacing) {
                HomeContentAdviceCard(onOpenEntry: onOpenEntry, onConnectKey: onConnectKey)
                HomeContentTodayCard(onWrite: onWrite, onOpenEntry: onOpenEntry)
//            }
//            .frame(maxWidth: .infinity)
//            VStack(spacing: HomeLayoutMetrics.sectionSpacing) {
                if homeViewModel.layout == .full {
                    HomePrinciplesSection(
                        principles: homeViewModel.principles,
                        entryCount: homeViewModel.entries.count,
                        showsBubbleBackground: true,
                        onSeeAll: { onSelectTab(.principles) },
                        onOpenEntry: onOpenEntry
                    )
                    if homeViewModel.showsWeeklySummary {
                        HomeContentWeeklySummary(isAlwaysExpanded: true, onOpenEntry: onOpenEntry)
                    }
                } else {
                    HomePrincipleProgressSection(entryCount: homeViewModel.entries.count)
                }
//            }
//            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }
}
