//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  HomeSectionsView.swift
//  MPA_ios
//
//  The cards and sections of 오늘 (Part A 3). Each one is stateless; HomeView wires them.
//

import SwiftUI

enum HomeLayoutMetrics {
    static let gutter: CGFloat = 20
    static let maxContentWidth: CGFloat = 640
    static let cardRadius: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let touchTarget: CGFloat = 44
    static let bubbleMinDiameter: CGFloat = 64
    static let bubbleMaxDiameter: CGFloat = 124
    static let bubbleAreaHeight: CGFloat = 230
}

private let principleColors: [Color] = [.PRINCIPLE1, .PRINCIPLE2, .PRINCIPLE3, .PRINCIPLE4, .PRINCIPLE5]

func homePrincipleColor(stage: Int) -> Color {
    principleColors[min(max(stage, 0), principleColors.count - 1)]
}

// MARK: - 3.2 Greeting

struct HomeGreetingHeader: View {
    let dateLine: String
    let greeting: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // iOS puts the date above the greeting (3.2).
            Text(dateLine)
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Text(greeting)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared pieces

/// "✦ 오늘의 조언" style header.
struct HomeAILabel: View {
    let title: String
    var size: CGFloat = 15

    var body: some View {
        HStack(spacing: 6) {
            Text("✦").font(.system(size: size - 2))
            Text(title).font(.system(size: size, weight: .semibold))
        }
        .foregroundStyle(Color.AI_ACCENT)
        .accessibilityElement(children: .combine)
    }
}

/// "참고한 일기" chip (3.4): capsule, white fill, hairline outline.
struct HomeSourceChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(Color.SURFACE, in: Capsule())
                .overlay(Capsule().stroke(Color.HAIRLINE, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(minHeight: HomeLayoutMetrics.touchTarget)
        .contentShape(Rectangle())
    }
}

private struct HomeSourceRow: View {
    let sources: [Journal]
    let onOpen: (Journal) -> Void

    var body: some View {
        if !sources.isEmpty {
            HStack(spacing: 8) {
                Text("참고한 일기")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                ForEach(sources, id: \.id) { entry in
                    HomeSourceChip(title: HomeViewModel.chipDate(entry.day)) { onOpen(entry) }
                }
            }
        }
    }
}

/// Fades the text in word by word (Part B 2, 120 ms per word).
struct HomeRevealText: View {
    let text: String
    let revealsByWord: Bool
    var size: CGFloat = 17

    @State private var visibleWords = Int.max
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var words: [Substring] { text.split(separator: " ", omittingEmptySubsequences: false) }

    var body: some View {
        Text(attributed)
            .font(.system(size: size))
            .lineSpacing(size * 0.5)
            .foregroundStyle(Color.TEXT_PRIMARY)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .accessibilityLabel(text)
            .task(id: text) {
                guard revealsByWord, !reduceMotion else { visibleWords = .max; return }
                visibleWords = 0
                for count in 1...max(words.count, 1) {
                    try? await Task.sleep(for: .milliseconds(120))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeIn(duration: 0.2)) { visibleWords = count }
                }
            }
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        for (index, word) in words.enumerated() {
            var part = AttributedString(index == 0 ? String(word) : " " + word)
            if index >= visibleWords { part.foregroundColor = .clear }
            result += part
        }
        return result
    }
}

private struct HomeSkeleton: View {
    let lines: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lines, id: \.self) { index in
                JournalShimmerLine(widthRatio: index == lines - 1 ? 0.6 : 1)
            }
        }
        .accessibilityLabel("만드는 중")
    }
}

private struct HomeIconButton: View {
    let systemName: String
    let label: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .frame(width: HomeLayoutMetrics.touchTarget, height: HomeLayoutMetrics.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }
}

/// Lavender AI card (Part B). Failure states switch to a neutral surface.
private struct HomeAICardBackground: ViewModifier {
    var isNeutral = false

    func body(content: Content) -> some View {
        content
            .padding(HomeLayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isNeutral ? Color.SUNKEN : Color.AI_TINT,
                in: .rect(cornerRadius: HomeLayoutMetrics.cardRadius, style: .continuous)
            )
    }
}

/// White card with a hairline outline.
private struct HomeSurfaceCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(HomeLayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.SURFACE, in: .rect(cornerRadius: HomeLayoutMetrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HomeLayoutMetrics.cardRadius, style: .continuous)
                    .stroke(Color.HAIRLINE, lineWidth: 1)
            }
    }
}

// MARK: - 3.3 오늘의 조언

struct HomeAdviceCard: View {
    let phase: HomeAIPhase
    let sources: [Journal]
    let revealsByWord: Bool
    let onOpenSource: (Journal) -> Void
    let onFeedback: (AIFeedback) -> Void
    let onRegenerate: () -> Void
    let onRetry: () -> Void
    let onCheckKey: () -> Void
    let onCallHelp: () -> Void
    let onOpenHelpResources: () -> Void

    var body: some View {
        switch phase {
        case .sensitive:
            JournalHelpResourceCard(onCall: onCallHelp, onOpenResources: onOpenHelpResources)
        case .failed:
            failure(message: "조언을 만들지 못했어요. 잠시 후 다시 시도해 주세요.", button: "다시 시도", action: onRetry)
        case .resting:
            Text("오늘은 쉬어 갈게요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .modifier(HomeAICardBackground(isNeutral: true))
        case .keyError:
            VStack(alignment: .leading, spacing: 8) {
                Text("내 API 키를 확인해 주세요")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text("Gemini가 키를 받지 않았어요. 사용 한도를 넘었거나 키가 만료됐을 수 있어요.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .fixedSize(horizontal: false, vertical: true)
                Button("키 확인", action: onCheckKey)
                    .buttonStyle(HomeCapsuleButtonStyle(isProminent: false))
                    .padding(.top, 4)
            }
            .modifier(HomeAICardBackground(isNeutral: true))
        case .idle, .loading, .loaded:
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeAILabel(title: "오늘의 조언")
            switch phase {
            case .loaded(let text):
                HomeRevealText(text: text.text, revealsByWord: revealsByWord, size: 19)
                HomeSourceRow(sources: sources, onOpen: onOpenSource)
                footer(text: text)
            default:
                HomeSkeleton(lines: 3)
                Text("기기에서 만드는 중…")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
        }
        .modifier(HomeAICardBackground())
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    private func footer(text: AIText) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(text.engine.sourceLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Picking one hides the other (Part B 3).
                if text.feedback != .notHelpful {
                    HomeIconButton(
                        systemName: text.feedback == .helpful ? "hand.thumbsup.fill" : "hand.thumbsup",
                        label: "도움됨"
                    ) { onFeedback(.helpful) }
                }
                if text.feedback != .helpful {
                    HomeIconButton(
                        systemName: text.feedback == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                        label: "도움 안 됨"
                    ) { onFeedback(.notHelpful) }
                }
                HomeIconButton(systemName: "arrow.clockwise", label: "다시 생성", action: onRegenerate)
            }
            .sensoryFeedback(.selection, trigger: text.feedback)
            if text.feedback == .notHelpful {
                Button("다른 조언 보기", action: onRegenerate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.BRAND_PRIMARY)
                    .frame(minHeight: HomeLayoutMetrics.touchTarget)
            }
        }
    }

    private func failure(message: String, button: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .fixedSize(horizontal: false, vertical: true)
            Button(button, action: action)
                .buttonStyle(HomeCapsuleButtonStyle(isProminent: false))
        }
        .modifier(HomeAICardBackground(isNeutral: true))
    }
}

/// Capsule button: filled ink indigo (primary) or outlined (secondary).
struct HomeCapsuleButtonStyle: ButtonStyle {
    var isProminent = true
    var isFullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isProminent ? Color.BRAND_ON_PRIMARY : Color.TEXT_PRIMARY)
            .padding(.horizontal, 22)
            .frame(minHeight: 48)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(isProminent ? Color.BRAND_PRIMARY : Color.SURFACE, in: Capsule())
            .overlay { if !isProminent { Capsule().stroke(Color.HAIRLINE, lineWidth: 1) } }
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - 3.6 오늘의 글감

struct HomePromptCard: View {
    let phase: HomeAIPhase
    let onWrite: (String) -> Void
    let onNextPrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeAILabel(title: "오늘의 글감", size: 14)
            if let prompt = phase.text?.text {
                Text(prompt)
                    .font(.system(size: 22))
                    .lineSpacing(6)
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else if phase == .failed {
                Text("질문을 만들지 못했어요.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            } else {
                HomeSkeleton(lines: 2)
            }
            HStack(spacing: 16) {
                Button {
                    if let prompt = phase.text?.text { onWrite(prompt) }
                } label: {
                    Label("쓰기", systemImage: "pencil")
                }
                .buttonStyle(HomeCapsuleButtonStyle())
                .disabled(phase.text == nil)

                Button(action: onNextPrompt) {
                    Label("다른 질문", systemImage: "arrow.clockwise")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(minHeight: HomeLayoutMetrics.touchTarget)
                }
                .buttonStyle(.plain)
                .disabled(phase == .loading)
            }
            .padding(.top, 8)
        }
        .modifier(HomeSurfaceCard())
        .animation(.easeInOut(duration: 0.2), value: phase)
    }
}

// MARK: - 3.7 오늘의 일기 미리보기

struct HomeTodayPreviewCard: View {
    let entry: Journal
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("오늘의 일기")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                        Spacer()
                        Text(HomeViewModel.timeText(entry.createdAt))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.TEXT_TERTIARY)
                    }
                    Text(entry.displayTitle)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.TEXT_PRIMARY)
                        .lineLimit(2)
                    Text(entry.previewText)
                        .font(.system(size: 16))
                        .lineSpacing(6)
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if entry.thumbnail != nil {
                    HomeThumbnail(seed: entry.id)
                        .padding(.top, 28)
                }
            }
            .multilineTextAlignment(.leading)
            .modifier(HomeSurfaceCard())
        }
        .buttonStyle(.plain)
        .accessibilityHint("오늘 일기 열기")
    }
}

/// 56pt photo placeholder (real images are not wired yet).
struct HomeThumbnail: View {
    let seed: UUID

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.SUNKEN)
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.TEXT_TERTIARY)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - 3.8 나의 원칙

struct HomeSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                }
            }
            Spacer()
            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.BRAND_PRIMARY)
                    .frame(minHeight: HomeLayoutMetrics.touchTarget)
            }
        }
    }
}

struct HomePrinciplesSection: View {
    let principles: [HomePrinciple]
    let entryCount: Int
    var showsBubbleBackground = false
    let onSeeAll: () -> Void
    let onOpenEntry: (Journal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(
                title: "나의 원칙",
                subtitle: "일기 \(entryCount)개에서 찾았어요",
                actionTitle: "전체 보기",
                action: onSeeAll
            )
            HomeBubbleCloud(principles: principles, onOpenEntry: onOpenEntry)
                .padding(.vertical, showsBubbleBackground ? 16 : 8)
                .background {
                    if showsBubbleBackground {
                        RoundedRectangle(cornerRadius: HomeLayoutMetrics.cardRadius, style: .continuous)
                            .fill(Color.SUNKEN.opacity(0.6))
                    }
                }
            HomeBubbleLegend()
                .frame(maxWidth: .infinity)
        }
    }
}

/// Bubbles packed around the center. Area ∝ entry count, minimum diameter 64 (3.8).
struct HomeBubbleCloud: View {
    let principles: [HomePrinciple]
    let onOpenEntry: (Journal) -> Void

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Slot centers (unit square) for the 1st…5th largest bubble, from the design.
    private static let slots: [CGPoint] = [
        CGPoint(x: 0.50, y: 0.55), CGPoint(x: 0.20, y: 0.33), CGPoint(x: 0.82, y: 0.24),
        CGPoint(x: 0.25, y: 0.78), CGPoint(x: 0.76, y: 0.80),
    ]

    private var ordered: [HomePrinciple] { principles.sorted { $0.count > $1.count } }

    var body: some View {
        GeometryReader { proxy in
            let maxCount = max(ordered.first?.count ?? 1, 1)
            ForEach(Array(ordered.prefix(Self.slots.count).enumerated()), id: \.element.id) { index, principle in
                let diameter = Self.diameter(count: principle.count, maxCount: maxCount)
                let slot = Self.slots[index]
                HomePrincipleBubble(principle: principle, diameter: diameter, onOpenEntry: onOpenEntry)
                    .position(
                        x: clamp(slot.x * proxy.size.width, diameter / 2, proxy.size.width - diameter / 2),
                        y: clamp(slot.y * proxy.size.height, diameter / 2, proxy.size.height - diameter / 2)
                    )
                    .offset(y: hasAppeared || reduceMotion ? 0 : 40)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.05),
                        value: hasAppeared
                    )
            }
        }
        .frame(height: HomeLayoutMetrics.bubbleAreaHeight)
        .onAppear { hasAppeared = true }
    }

    static func diameter(count: Int, maxCount: Int) -> CGFloat {
        let ratio = sqrt(Double(count) / Double(max(maxCount, 1)))
        return max(HomeLayoutMetrics.bubbleMinDiameter, HomeLayoutMetrics.bubbleMaxDiameter * ratio)
    }

    private func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(max(value, low), max(low, high))
    }
}

/// One bubble. Long press opens the related-entries menu with the system lift and blur.
struct HomePrincipleBubble: View {
    let principle: HomePrinciple
    let diameter: CGFloat
    let onOpenEntry: (Journal) -> Void

    var body: some View {
        bubble
            .contentShape(.contextMenuPreview, Circle())
            .contextMenu {
                Section("\(principle.name)\n\(principle.count)개의 일기에서 발견") {
                    ForEach(principle.related, id: \.id) { entry in
                        Button {
                            onOpenEntry(entry)
                        } label: {
                            Text(entry.displayTitle)
                            Text(HomeViewModel.dateLine(entry.day))
                        }
                    }
                }
            } preview: {
                bubble.scaleEffect(1.08).padding(8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("원칙: \(principle.name), \(principle.stage == 0 ? "최근" : "\(principle.stage + 1)단계"), \(principle.count)개 일기에서 등장")
            .accessibilityAddTraits(.isButton)
    }

    private var bubble: some View {
        Circle()
            .fill(homePrincipleColor(stage: principle.stage))
            .frame(width: diameter, height: diameter)
            .overlay {
                Text(principle.name)
                    .font(.system(size: diameter > 100 ? 22 : 18, weight: .bold))
                    .foregroundStyle(Color.ON_PRINCIPLE)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(8)
            }
    }
}

/// 3.10 "최근 ● … ● 오래됨 · 크기 = 등장 빈도".
struct HomeBubbleLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("최근")
            HStack(spacing: 4) {
                ForEach(0..<principleColors.count, id: \.self) { index in
                    Circle().fill(principleColors[index]).frame(width: 10, height: 10)
                }
            }
            Text("오래됨")
            Text("·").foregroundStyle(Color.TEXT_TERTIARY)
            Text("크기 = 등장 빈도")
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.TEXT_SECONDARY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("색은 최근부터 오래된 순, 크기는 등장 빈도")
    }
}

// MARK: - 3.9 원칙 진행 표시

struct HomePrincipleProgressSection: View {
    let entryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(title: "나의 원칙")
            HStack(spacing: 24) {
                ZStack {
                    Circle().stroke(Color.PRINCIPLE1, lineWidth: 2).frame(width: 40, height: 40).offset(x: -10, y: 6)
                    Circle().stroke(Color.PRINCIPLE3, lineWidth: 2).frame(width: 22, height: 22).offset(x: 16, y: -14)
                    Circle().stroke(Color.TEXT_TERTIARY, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 16, height: 16).offset(x: 20, y: 22)
                }
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 12) {
                    Text("일기가 3개 이상 쌓이면\n원칙을 찾아드려요")
                        .font(.system(size: 16))
                        .lineSpacing(4)
                        .foregroundStyle(Color.TEXT_PRIMARY)
                    HStack(spacing: 8) {
                        ForEach(0..<HomeViewModel.principleThreshold, id: \.self) { index in
                            Capsule()
                                .fill(index < entryCount ? Color.BRAND_PRIMARY : Color.SUNKEN)
                                .frame(width: 28, height: 6)
                        }
                        Text("\(entryCount) / \(HomeViewModel.principleThreshold)")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                            .padding(.leading, 4)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("원칙 분석까지 \(entryCount) / \(HomeViewModel.principleThreshold)")
                    .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding(HomeLayoutMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: HomeLayoutMetrics.cardRadius, style: .continuous)
                    .stroke(Color.HAIRLINE, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
        }
    }
}

// MARK: - 3.11 이번 주 요약

struct HomeWeeklySummaryCard: View {
    let phase: HomeAIPhase
    let rangeLine: String
    let isExpanded: Bool
    let sources: [Journal]
    /// Tablet shows the summary open, with the range under the text.
    var isAlwaysExpanded = false
    let onToggle: () -> Void
    let onRetry: () -> Void
    let onOpenSource: (Journal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: isAlwaysExpanded ? {} : onToggle) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        HomeAILabel(title: "이번 주 요약", size: 20)
                            .foregroundStyle(Color.TEXT_PRIMARY)
                        if !isAlwaysExpanded {
                            Text(collapsedLine)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.TEXT_SECONDARY)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    if !isAlwaysExpanded {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.TEXT_SECONDARY)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")

            if isExpanded || isAlwaysExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .modifier(HomeAICardBackground(isNeutral: phase == .failed || phase == .resting))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    private var collapsedLine: String {
        [rangeLine, HomeSamples.weeklyMood].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    @ViewBuilder
    private var expandedContent: some View {
        switch phase {
        case .loaded(let text):
            Text(text.text)
                .font(.system(size: 16))
                .lineSpacing(6)
                .foregroundStyle(Color.TEXT_PRIMARY)
                .fixedSize(horizontal: false, vertical: true)
            if isAlwaysExpanded {
                Text(rangeLine)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            } else {
                HomeSourceRow(sources: sources, onOpen: onOpenSource)
            }
        case .failed:
            Text("요약을 만들지 못했어요. 잠시 후 다시 시도해 주세요.")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Button("다시 시도", action: onRetry)
                .buttonStyle(HomeCapsuleButtonStyle(isProminent: false))
        case .resting:
            Text("오늘은 쉬어 갈게요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
        default:
            HomeSkeleton(lines: 3)
        }
    }
}

// MARK: - 3.13 일기 앱 모드

struct HomeDiaryTodayCard: View {
    let onWrite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 일기")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Text("오늘 하루를 몇 줄로 남겨보세요")
                .font(.system(size: 22))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 4)
            Text("짧아도 괜찮아요.")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Button(action: onWrite) {
                Label("쓰기", systemImage: "pencil")
            }
            .buttonStyle(HomeCapsuleButtonStyle())
            .padding(.top, 12)
        }
        .modifier(HomeSurfaceCard())
    }
}

struct HomeWeekStrip: View {
    let days: [HomeWeekDay]
    let onSelect: (HomeWeekDay) -> Void
    let onOpenCalendar: () -> Void
    let onChangeWeek: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(title: "이번 주", actionTitle: "캘린더", action: onOpenCalendar)
            HStack(spacing: 4) {
                ForEach(days) { day in
                    Button { onSelect(day) } label: { cell(day) }
                        .buttonStyle(.plain)
                        .disabled(day.isFuture)
                        .frame(maxWidth: .infinity)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 24).onEnded { value in
                    if value.translation.width > 40 { onChangeWeek(-1) }
                    if value.translation.width < -40 { onChangeWeek(1) }
                }
            )
        }
    }

    private func cell(_ day: HomeWeekDay) -> some View {
        let calendar = Calendar.current
        let weekday = ["일", "월", "화", "수", "목", "금", "토"][calendar.component(.weekday, from: day.date) - 1]
        let color: Color = day.isToday ? .BRAND_PRIMARY : (day.isFuture ? .TEXT_TERTIARY : .TEXT_PRIMARY)
        return VStack(spacing: 6) {
            Text(weekday)
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(day.isToday ? Color.BRAND_PRIMARY : Color.TEXT_SECONDARY)
            Text("\(calendar.component(.day, from: day.date))")
                .font(.system(size: 20, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(color)
            Circle()
                .fill(day.hasEntry ? Color.BRAND_PRIMARY : .clear)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.vertical, 6)
        .overlay {
            // iOS marks today with an outline (3.13).
            if day.isToday {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(HomeViewModel.dateLine(day.date) + (day.hasEntry ? ", 일기 있음" : ""))
    }
}

struct HomeRecentSection: View {
    let entries: [Journal]
    let onOpen: (Journal) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HomeSectionHeader(title: "최근 기록", actionTitle: "모두 보기", action: onSeeAll)
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                Button { onOpen(entry) } label: { HomeRecentRow(entry: entry) }
                    .buttonStyle(.plain)
                if index < entries.count - 1 {
                    Divider().overlay(Color.HAIRLINE)
                }
            }
        }
    }
}

/// Date block + title + 2-line body + thumbnail. No keyword chips (3.13).
struct HomeRecentRow: View {
    let entry: Journal
    var isHighlighted = false

    var body: some View {
        let calendar = Calendar.current
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: entry.day))")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text(["일", "월", "화", "수", "목", "금", "토"][calendar.component(.weekday, from: entry.day) - 1])
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.displayTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineLimit(2)
                Text(entry.previewText)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if entry.thumbnail != nil {
                HomeThumbnail(seed: entry.id)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, isHighlighted ? 12 : 0)
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.SURFACE)
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 3.14 첫 실행

struct HomeFirstRunSection: View {
    /// nil hides the line (no AI: the warning button explains instead).
    let privacyLine: String?
    let onWrite: () -> Void
    let onQuestion: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HomeEmptyIllustration()
                .frame(height: 230)
            Text("첫 일기를 써보세요")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 8)
            Text("몇 줄이면 충분해요. 일기가 쌓이면\n그 안에서 나만의 원칙을 찾아드릴게요.")
                .font(.system(size: 16))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.TEXT_SECONDARY)
                .padding(.top, 10)
            Button(action: onWrite) {
                Label("첫 일기 쓰기", systemImage: "pencil")
            }
            .buttonStyle(HomeCapsuleButtonStyle(isFullWidth: true))
            .padding(.top, 28)
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("이런 질문으로 시작해 보세요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .padding(.bottom, 4)
                ForEach(HomeSamples.exampleQuestions, id: \.self) { question in
                    Button { onQuestion(question) } label: {
                        HStack {
                            Text(question)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.TEXT_PRIMARY)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.TEXT_TERTIARY)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(Color.SURFACE, in: .rect(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 32)

            if let privacyLine {
                Label(privacyLine, systemImage: "lock")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Line drawing in one color + three principle dots (3.14). Dark mode uses the secondary text color.
struct HomeEmptyIllustration: View {
    var body: some View {
        ZStack {
            Image(systemName: "book")
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Image(systemName: "pencil")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .offset(x: 84, y: -10)
            Circle().stroke(Color.PRINCIPLE5, lineWidth: 2).frame(width: 14, height: 14).offset(x: 22, y: -98)
            Circle().stroke(Color.PRINCIPLE1, lineWidth: 2).frame(width: 34, height: 34).offset(x: 54, y: -84)
            Circle().stroke(Color.PRINCIPLE3, lineWidth: 2).frame(width: 18, height: 18).offset(x: 94, y: -94)
        }
        .accessibilityHidden(true)
    }
}
