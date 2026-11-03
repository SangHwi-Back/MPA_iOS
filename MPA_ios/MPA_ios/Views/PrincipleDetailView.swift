//
//  PrincipleDetailView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//


import SwiftUI

struct PrincipleDetailView: View {
    let principle: Principle
    let relatedJournals: [Journal]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                descriptionBlock
                statPills
                barChartSection
                relatedJournalsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.CANVAS.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
    }
    
    // MARK: Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(principle.bubbleColor)
                .frame(width: 48, height: 48)
            
            Text(principle.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.TEXT_PRIMARY)
            
            Text(principle.detailSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.TEXT_SECONDARY)
        }
    }
    
    // MARK: Description
    
    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(principle.category.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(principle.bubbleColor)
            
            if let desc = principle.principleDescription {
                Text(desc.text)
                    .font(.body)
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(desc.engine.sourceLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.AI_ACCENT)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Stat pills
    
    private var statPills: some View {
        HStack(spacing: 12) {
            statPill(title: "처음 등장", value: formatDate(principle.firstSeenDate))
            statPill(title: "등장 횟수", value: "\(principle.frequency)번")
            statPill(title: "마지막",   value: formatDate(principle.lastSeenDate))
        }
    }
    
    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.TEXT_TERTIARY)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.SURFACE)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
    
    // MARK: Bar chart
    
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 8주 등장 횟수")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            
            PrincipleBarChart(
                counts:  principle.weeklyCounts,
                labels:  principle.weekLabels,
                color:   principle.bubbleColor,
                activeColor: Color.BRAND_PRIMARY
            )
        }
    }
    
    // MARK: Related journals
    
    private var relatedJournalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("관련 일기")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            
            ForEach(relatedJournals) { journal in
                RelatedJournalRow(journal: journal)
            }
        }
    }
    
    // MARK: Helpers
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }
    
    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                // share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            Button {
                // more
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
        }
    }
}

// MARK: - 8-week bar chart

private struct PrincipleBarChart: View {
    let counts: [Int]
    let labels: [String]
    let color: Color
    let activeColor: Color
    
    private var maxCount: Int { max(counts.max() ?? 1, 1) }
    
    var body: some View {
        VStack(spacing: 8) {
            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(counts.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(i == counts.count - 1 ? activeColor : color.opacity(0.6))
                            .frame(
                                width: 20,
                                height: max(CGFloat(counts[i]) / CGFloat(maxCount) * 80, 6)
                            )
                    }
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Week labels
            HStack(spacing: 8) {
                ForEach(labels.indices, id: \.self) { i in
                    Text(labels[i])
                        .font(.system(size: 9))
                        .foregroundStyle(Color.TEXT_TERTIARY)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Related journal row

private struct RelatedJournalRow: View {
    let journal: Journal
    
    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: journal.day)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(dateLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.TEXT_TERTIARY)
                .frame(width: 52, alignment: .leading)
            
            Text(journal.displayTitle)
                .font(.subheadline)
                .foregroundStyle(Color.TEXT_PRIMARY)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.TEXT_TERTIARY)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview("원칙 – 상세 (경청)") {
    PrincipleDetailView(
        principle: (
            Principle.sampleCurrent().first ??
            Principle(
                id: UUID(),
                name: "경청",
                rank: 1,
                frequency: 7,
                firstSeenDate: Calendar.current.date(from: .init(year: 2026, month: 9, day: 14)) ?? .now,
                lastSeenDate:  Calendar.current.date(from: .init(year: 2026, month: 10, day: 27)) ?? .now,
                isCore: true,
                isNew: true,
                isCurrent: true,
                category: .morning,
                principleDescription: AIText(
                    text: "다른 사람의 발화를 끝까지 듣고, 내 생각보다 그 질문을 먼저 기다렸다는 태도예요.",
                    engine: .appleIntelligence,
                    generatedAt: .now,
                    sourceJournalIDs: []
                ),
                weeklyCounts: [1, 1, 0, 1, 1, 0, 2, 1],
                relatedJournalIDs: [],
                appearancePeriod: "9월 ~ 10월",
                weekDuration: 10
            )
        ),
        relatedJournals: Principle.sampleRelatedJournals()
    )
}
