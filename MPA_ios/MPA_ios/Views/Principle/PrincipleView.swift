//
//  PrincipleView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

// MARK: - Root

struct PrincipleView: View {
    
    @State private var currentPrinciples: [Principle] = []
    @State private var pastPrinciples: [Principle] = []
    @State private var relatedJournals: [Journal] = []
    
    @State private var selectedPrinciple: Principle?
    
    var body: some View {
        NavigationStack {
            principalListView
                .background(content: {
                    Color.CANVAS
                })
                .task { loadSampleData() }
                .navigationDestination(for: Principle.self) { p in
                    PrincipleDetailView(
                        principle: p,
                        relatedJournals: relatedJournals
                            .filter { _ in p.relatedJournalIDs.contains(where: {$0 == p.id}) }
                    )
                }
        }
    }
    
    // MARK: - List
    
    private var principalListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                principalHeader
                currentPrinciplesSection
                pastPrinciplesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Header
    
    private var principalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("원칙")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                
                Text(metaSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            
            Spacer()
            
            Button {
                // overflow menu – sheet / popover
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var metaSubtitle: String {
        let total = currentPrinciples.count + pastPrinciples.count
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        let latest = currentPrinciples
            .map({$0.lastSeenDate})
            .max() ?? .now
        return "일기 \(total)개에서 발췄어요 · \(f.string(from: latest)) 갱신"
    }
    
    // MARK: - Current principles
    
    private var currentPrinciplesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("지금은 원칙")
            
            ForEach(currentPrinciples) { p in
                NavigationLink(value: p) {
                    PrincipleRowView(principle: p, rank: p.rank ?? 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Past principles
    
    private var pastPrinciplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("지난년 원칙")
            
            ForEach(pastPrinciples) { p in
                PastPrincipleRowView(principle: p)
            }
        }
    }
    
    // MARK: - Section label
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.TEXT_TERTIARY)
            .textCase(.uppercase)
    }
    
    // MARK: - Data
    
    private func loadSampleData() {
        currentPrinciples = Principle.sampleCurrent()
        pastPrinciples    = Principle.samplePast()
        relatedJournals    = Principle.sampleRelatedJournals()
    }
}

// MARK: - Current principle row

private struct PrincipleRowView: View {
    let principle: Principle
    let rank: Int
    
    var body: some View {
        HStack(spacing: 14) {
            // Colored rank circle
            ZStack {
                Circle()
                    .fill(principle.bubbleColor)
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ON_PRINCIPLE)
            }
            
            // Name + badges
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(principle.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.TEXT_PRIMARY)
                    
                    if principle.isCore {
                        badge("핵심", color: Color.BRAND_PRIMARY)
                    }
                    if principle.isNew {
                        badge("새로", color: Color.DANGER)
                    }
                }
                
                Text(principle.currentRowSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Mini progress bar
            miniProgress
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.12))
            )
    }
    
    private var miniProgress: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.SUNKEN)
                Capsule()
                    .fill(principle.bubbleColor)
                    .frame(width: geo.size.width * progressFill)
            }
        }
        .frame(width: 48, height: 6)
    }
    
    private var progressFill: Double {
        let maxFreq = 10.0  // adjust or pass in
        return min(Double(principle.frequency) / maxFreq, 1.0)
    }
}

// MARK: - Past principle row

private struct PastPrincipleRowView: View {
    let principle: Principle
    
    var body: some View {
        HStack(spacing: 10) {
            // Hollow circle
            Circle()
                .stroke(Color.TEXT_TERTIARY.opacity(0.4), lineWidth: 1.5)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(principle.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.TEXT_TERTIARY)
                
                Text(principle.pastRowSubtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.TEXT_TERTIARY.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .opacity(0.75)
    }
}

// MARK: - Preview

#Preview("원칙 – 리스트") {
    NavigationStack {
        PrincipleView()
    }
}
