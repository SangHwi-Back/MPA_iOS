//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  HomeViewComponents.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/12/26.
//

import SwiftUI

struct HomeContentAdviceCard: View {
    let onOpenEntry: (Journal) -> Void
    let onConnectKey: () -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HomeAdviceCard(
            phase: homeViewModel.advicePhase,
            sources: homeViewModel.advicePhase.text.map(homeViewModel.sources(of:)) ?? [],
            revealsByWord: homeViewModel.revealsAdviceByWord,
            onOpenSource: onOpenEntry,
            onFeedback: homeViewModel.toggleFeedback,
            onRegenerate: { Task { await homeViewModel.regenerateAdvice() } },
            onRetry: { Task { await homeViewModel.generateAdvice() } },
            onCheckKey: onConnectKey,
            onCallHelp: { openURL(URL(string: "tel:109")!) },
            onOpenHelpResources: {}
        )
    }
}

/// Today's entry if there is one, otherwise the 글감 card.
struct HomeContentTodayCard: View {
    let onWrite: (_ date: Date?, _ prompt: String?) -> Void
    let onOpenEntry: (Journal) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        if let entry = homeViewModel.todayEntry {
            HomeTodayPreviewCard(entry: entry) { onOpenEntry(entry) }
        } else {
            HomePromptCard(
                phase: homeViewModel.promptPhase,
                onWrite: { onWrite(nil, $0) },
                onNextPrompt: { Task { await homeViewModel.nextPrompt() } }
            )
        }
    }
}

struct HomeContentWeeklySummary: View {
    let isAlwaysExpanded: Bool
    let onOpenEntry: (Journal) -> Void
    
    @Environment(HomeViewModel.self) private var homeViewModel: HomeViewModel
    
    var body: some View {
        HomeWeeklySummaryCard(
            phase: homeViewModel.summaryPhase,
            rangeLine: homeViewModel.weeklyRangeLine,
            isExpanded: homeViewModel.isSummaryExpanded,
            sources: homeViewModel.summaryPhase.text.map(homeViewModel.sources(of:)) ?? [],
            isAlwaysExpanded: isAlwaysExpanded,
            onToggle: { homeViewModel.isSummaryExpanded.toggle() },
            onRetry: { Task { await homeViewModel.generateSummary() } },
            onOpenSource: onOpenEntry
        )
    }
}
