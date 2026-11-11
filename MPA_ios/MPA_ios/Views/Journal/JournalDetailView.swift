//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalDetailView.swift
//  MPA_ios
//

import SwiftUI

private extension Color {
    static let detailPrincipleScale: [Color] = [.PRINCIPLE1, .PRINCIPLE2, .PRINCIPLE3, .PRINCIPLE4, .PRINCIPLE5]
    /// Alternating tints so neighboring photo placeholders read as separate tiles.
    static let detailPhotoPlaceholders: [Color] = [
        Color.mpa("#D7DBE4", dark: "#2B2D33"),
        Color.mpa("#DED6CB", dark: "#2E2B28"),
    ]

    static func principle(stage: Int) -> Color {
        detailPrincipleScale[min(max(stage, 0), detailPrincipleScale.count - 1)]
    }
}

enum JournalDetailLayout {
    static let gutter: CGFloat = 20
    static let readableWidth: CGFloat = 680
    static let chipHeight: CGFloat = 34
    static let photoSpacing: CGFloat = 8
    static let photoRadius: CGFloat = 12
    static let cardRadius: CGFloat = 24
    static let commentHeaderHeight: CGFloat = 56
    static let actionSize: CGFloat = 44
    static let bodySize: CGFloat = 17
    static let sheetRowHeight: CGFloat = 56
}

private struct PresentedKeyword: Identifiable {
    let name: String
    var id: String { name }
}

/// Part B — reads one entry. Editing happens in the editor.
struct JournalDetailView: View {

    @ObservedObject var journalViewModel: JournalViewModel
    @State private var model: JournalDetailViewModel

    var onOpenEntry: (Journal) -> Void
    var onEdit: (Journal) -> Void
    var onDelete: (Journal) -> Void
    var onOpenPrinciple: (String) -> Void
    var onOpenPhoto: (Journal, Int) -> Void
    var onOpenHelpResources: () -> Void

    private let startsAtBottom: Bool

    /// The title's bottom edge in content coordinates (0 = top of the scrolled content).
    @State private var titleBottom: CGFloat?
    @State private var isTitleScrolledAway = false
    @State private var isDatePickerPresented = false
    @State private var pendingDay = Date.now
    @Environment(\.openURL) private var openURL

    init(
        journal: Journal,
        journalViewModel: JournalViewModel,
        generator: any JournalCommentGenerating = StubJournalCommentGenerator(),
        isCommentExpanded: Bool = false,
        presentedKeyword: String? = nil,
        startsAtBottom: Bool = false,
        onOpenEntry: @escaping (Journal) -> Void = { _ in },
        onEdit: @escaping (Journal) -> Void = { _ in },
        onDelete: @escaping (Journal) -> Void = { _ in },
        onOpenPrinciple: @escaping (String) -> Void = { _ in },
        onOpenPhoto: @escaping (Journal, Int) -> Void = { _, _ in },
        onOpenHelpResources: @escaping () -> Void = {}
    ) {
        self.journalViewModel = journalViewModel
        self._model = State(initialValue: JournalDetailViewModel(
            journal: journal,
            generator: generator,
            isCommentExpanded: isCommentExpanded,
            presentedKeyword: presentedKeyword
        ))
        self.startsAtBottom = startsAtBottom
        self.onOpenEntry = onOpenEntry
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onOpenPrinciple = onOpenPrinciple
        self.onOpenPhoto = onOpenPhoto
        self.onOpenHelpResources = onOpenHelpResources
    }

    private var journal: Journal { model.journal }

    /// The date replaces the title in the bar when there is no title or it has scrolled away.
    private var barTitle: String {
        (!model.hasTitle || isTitleScrolledAway) ? JournalDetailViewModel.shortDate(journal.day) : ""
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: JournalDetailLayout.readableWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
                .coordinateSpace(.named(DetailCoordinateSpace.content))
        }
        .defaultScrollAnchor(startsAtBottom ? .bottom : .top)
        // The transform reads `titleBottom`, so it is re-evaluated once the title is measured.
        // That also covers a screen that opens already scrolled, where no scroll change follows.
        .onScrollGeometryChange(for: Bool.self) { geometry in
            guard model.hasTitle, let titleBottom else { return false }
            return geometry.contentOffset.y + geometry.contentInsets.top > titleBottom
        } action: { _, isHidden in
            isTitleScrolledAway = isHidden
        }
        .background(Color.CANVAS.ignoresSafeArea())
        .navigationTitle(barTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: presentedKeywordBinding) { keyword in
            keywordSheet(for: keyword.name)
        }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
        }
    }

    private var presentedKeywordBinding: Binding<PresentedKeyword?> {
        Binding(
            get: { model.presentedKeyword.map(PresentedKeyword.init) },
            set: { model.presentedKeyword = $0?.name }
        )
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.isAIAvailable {
                keywordRow
            }

            Text(JournalDetailViewModel.dateLine(day: journal.day, createdAt: journal.createdAt))
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)

            if model.hasTitle {
                Text(journal.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named(DetailCoordinateSpace.content)).maxY
                    } action: { titleBottom = $0 }
            }

            bodyText
                .padding(.top, model.hasTitle ? 22 : 12)

            if !journal.photos.isEmpty {
                photoGrid
                    .padding(.top, 28)
            }

            if model.isSensitive {
                JournalHelpResourceCard(
                    onCall: { openURL(URL(string: "tel:109")!) },
                    onOpenResources: onOpenHelpResources
                )
                .padding(.top, 28)
            } else if model.isAIAvailable {
                JournalCommentCard(model: model)
                    .padding(.top, 28)
            }

            if let editedAt = journal.editedAt {
                Text(JournalDetailViewModel.editedLine(editedAt))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }
        }
        .padding(.horizontal, JournalDetailLayout.gutter)
        .padding(.top, 8)
        .padding(.bottom, 48)
    }

    @ViewBuilder
    private var keywordRow: some View {
        switch model.keywordRow {
        case .hidden:
            EmptyView()
        case .skeleton:
            HStack(spacing: 8) {
                ForEach([64, 84], id: \.self) { width in
                    Capsule()
                        .fill(Color.AI_TINT)
                        .frame(width: CGFloat(width), height: JournalDetailLayout.chipHeight)
                }
            }
            .padding(.bottom, 24)
            .accessibilityElement()
            .accessibilityLabel("키워드를 찾는 중")
        case .chips(let keywords):
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(keywords, id: \.name) { keyword in
                        JournalDetailKeywordChip(
                            name: keyword.name,
                            stage: journalViewModel.keywordStages[keyword.name] ?? 0
                        ) {
                            model.presentedKeyword = keyword.name
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .padding(.bottom, 24)
        }
    }

    private var bodyText: some View {
        // Line spacing is not added after a paragraph's last line, so it is added to the 16pt paragraph gap.
        VStack(alignment: .leading, spacing: 16 + JournalDetailLayout.bodySize * 0.75) {
            ForEach(Array(model.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.system(size: JournalDetailLayout.bodySize))
                    .lineSpacing(JournalDetailLayout.bodySize * 0.75)
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    // MARK: - Photos

    @ViewBuilder
    private var photoGrid: some View {
        let photos = journal.photos
        if photos.count == 1, let photo = photos.first {
            photoCell(photo, index: 0, aspectRatio: 4.0 / 3.0)
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: JournalDetailLayout.photoSpacing, alignment: .top),
                    GridItem(.flexible(), alignment: .top),
                ],
                alignment: .leading,
                spacing: 16
            ) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    photoCell(photo, index: index, aspectRatio: 1)
                }
            }
        }
    }

    private func photoCell(_ photo: JournalPhoto, index: Int, aspectRatio: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                onOpenPhoto(journal, index)
            } label: {
                RoundedRectangle(cornerRadius: JournalDetailLayout.photoRadius, style: .continuous)
                    .fill(Color.detailPhotoPlaceholders[index % Color.detailPhotoPlaceholders.count])
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .overlay {
                        Image("image_placeholder_glyph")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(photo.caption.isEmpty ? "사진 \(index + 1)" : photo.caption)

            if !photo.caption.isEmpty {
                Text(photo.caption)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                onEdit(journal)
            } label: {
                Image("edit")
                    .renderingMode(.template)
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .accessibilityLabel("편집")

            Menu {
                ShareLink(item: shareText) {
                    Label("공유", systemImage: "square.and.arrow.up")
                }
                Button {
                    pendingDay = journal.day
                    isDatePickerPresented = true
                } label: {
                    Label("날짜 변경", systemImage: "calendar")
                }
                Button(role: .destructive) {
                    onDelete(journal)
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .accessibilityLabel("더보기")
        }
    }

    private var shareText: String {
        [journal.title, journal.body]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
    }

    // MARK: - Sheets

    @ViewBuilder
    private func keywordSheet(for name: String) -> some View {
        if let summary = JournalDetailViewModel.keywordSummary(
            named: name,
            in: journalViewModel.entries,
            stages: journalViewModel.keywordStages
        ) {
            JournalKeywordSheet(
                summary: summary,
                currentJournalID: journal.id,
                onClose: { model.presentedKeyword = nil },
                onOpenPrinciple: {
                    model.presentedKeyword = nil
                    onOpenPrinciple(name)
                },
                onOpenEntry: { entry in
                    model.presentedKeyword = nil
                    onOpenEntry(entry)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("날짜", selection: $pendingDay, in: ...journalViewModel.today, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.BRAND_PRIMARY)
                .padding(.horizontal, 16)
                .navigationTitle("날짜 변경")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isDatePickerPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            model.changeDay(to: pendingDay)
                            journalViewModel.objectWillChange.send()
                            isDatePickerPresented = false
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

private enum DetailCoordinateSpace: Hashable {
    case content
}

// MARK: - Keyword chip

private struct JournalDetailKeywordChip: View {
    let name: String
    let stage: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.principle(stage: stage))
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.AI_ACCENT)
            }
            .padding(.horizontal, 14)
            .frame(height: JournalDetailLayout.chipHeight)
            .background(Capsule().fill(Color.AI_TINT))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("키워드 \(name)")
        .accessibilityHint("이 키워드가 나온 일기를 봐요")
    }
}

// MARK: - AI comment

private struct JournalCommentCard: View {
    let model: JournalDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Task { await model.toggleComment() }
            } label: {
                HStack(spacing: 12) {
                    Image("sparkle")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Color.AI_ACCENT)
                        .accessibilityHidden(true)
                    Text("이 일기에 대한 AI 한마디")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.TEXT_PRIMARY)
                    Spacer(minLength: 8)
                    Image("expand_more")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .rotationEffect(.degrees(model.isCommentExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .frame(height: JournalDetailLayout.commentHeaderHeight)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(model.isCommentExpanded ? "펼쳐짐" : "접힘")

            if model.isCommentExpanded {
                expandedContent
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .background(Color.AI_TINT, in: .rect(cornerRadius: JournalDetailLayout.cardRadius, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: model.isCommentExpanded)
        .animation(.easeInOut(duration: 0.25), value: model.commentPhase)
    }

    @ViewBuilder
    private var expandedContent: some View {
        switch model.commentPhase {
        case .idle, .loading:
            VStack(alignment: .leading, spacing: 12) {
                JournalShimmerLine(widthRatio: 1)
                JournalShimmerLine(widthRatio: 0.7)
            }
            .padding(.top, 4)
            .padding(.bottom, 20)
            .accessibilityElement()
            .accessibilityLabel("AI 한마디를 만드는 중")
        case .loaded(let comment):
            VStack(alignment: .leading, spacing: 8) {
                JournalCommentText(text: comment.text, revealsByWord: model.revealsCommentByWord)
                footer(comment)
            }
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 한마디를 만들지 못했어요.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                Button("다시 시도") {
                    Task { await model.generateComment() }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .frame(minHeight: JournalDetailLayout.actionSize)
            }
        }
    }

    private func footer(_ comment: AIText) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(comment.engine.sourceLabel)
                .font(.system(size: 13))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            feedbackButton(.helpful, comment: comment, image: "thumb_up", label: "도움이 됐어요")
            feedbackButton(.notHelpful, comment: comment, image: "thumb_down", label: "도움이 안 됐어요")
            Button {
                Task { await model.regenerateComment() }
            } label: {
                actionIcon("refresh")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("다시 생성")
        }
        .sensoryFeedback(.selection, trigger: comment.feedback)
    }

    private func feedbackButton(_ feedback: AIFeedback, comment: AIText, image: String, label: String) -> some View {
        let isSelected = comment.feedback == feedback
        return Button {
            model.toggleFeedback(feedback)
        } label: {
            actionIcon(isSelected ? image + "_filled" : image)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func actionIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .frame(width: JournalDetailLayout.actionSize, height: JournalDetailLayout.actionSize)
            .contentShape(.rect)
    }
}

/// Fades the comment in word by word right after it is generated.
private struct JournalCommentText: View {
    let text: String
    let revealsByWord: Bool

    @State private var visibleWords = Int.max

    private var words: [Substring] { text.split(separator: " ", omittingEmptySubsequences: false) }

    var body: some View {
        Text(attributed)
            .font(.system(size: JournalDetailLayout.bodySize))
            .lineSpacing(10)
            .foregroundStyle(Color.TEXT_PRIMARY)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
            .task(id: text) {
                guard revealsByWord else {
                    visibleWords = .max
                    return
                }
                visibleWords = 0
                for count in 1...max(words.count, 1) {
                    try? await Task.sleep(for: .milliseconds(60))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeIn(duration: 0.2)) { visibleWords = count }
                }
            }
    }

    /// Hidden words keep their space so the lines do not reflow while revealing.
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

struct JournalShimmerLine: View {
    let widthRatio: CGFloat
    @State private var isBright = false

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.AI_ACCENT.opacity(isBright ? 0.16 : 0.08))
                .frame(width: proxy.size.width * widthRatio)
        }
        .frame(height: 14)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isBright = true
            }
        }
    }
}

// MARK: - Help resources

/// Replaces the AI comment when the entry reads as a crisis. Always expanded, no ✦ or feedback.
struct JournalHelpResourceCard: View {
    let onCall: () -> Void
    let onOpenResources: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("마음이 많이 무거운 날이었나 봐요")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Text("혼자 견디지 않아도 괜찮아요. 지금 이야기를 들어줄 곳이 있어요.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(Color.TEXT_SECONDARY)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { buttons }
                VStack(alignment: .leading, spacing: 8) { buttons }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.SURFACE, in: .rect(cornerRadius: JournalDetailLayout.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: JournalDetailLayout.cardRadius, style: .continuous)
                .stroke(Color.HAIRLINE, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button(action: onCall) {
            Text("109 자살예방상담전화")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.BRAND_ON_PRIMARY)
                .padding(.horizontal, 16)
                .frame(minHeight: JournalDetailLayout.actionSize)
                .background(Capsule().fill(Color.BRAND_PRIMARY))
        }
        .buttonStyle(.plain)

        Button(action: onOpenResources) {
            Text("다른 상담 창구")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.BRAND_PRIMARY)
                .padding(.horizontal, 16)
                .frame(minHeight: JournalDetailLayout.actionSize)
                .overlay(Capsule().stroke(Color.HAIRLINE, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyword sheet

private struct JournalKeywordSheet: View {
    let summary: JournalKeywordSummary
    let currentJournalID: UUID
    let onClose: () -> Void
    let onOpenPrinciple: () -> Void
    let onOpenEntry: (Journal) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Color.HAIRLINE).frame(height: 1)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(summary.entries, id: \.id) { entry in
                        row(entry)
                        Rectangle().fill(Color.HAIRLINE).frame(height: 1)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color.principle(stage: summary.stage))
                .frame(width: 22, height: 22)
                .padding(.top, 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .accessibilityAddTraits(.isHeader)
                Text("\(summary.entries.count)개의 일기에서 발견 · 처음 \(JournalDetailViewModel.shortDate(summary.firstSeen))")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.TEXT_SECONDARY)

                if summary.isPrinciple {
                    Button(action: onOpenPrinciple) {
                        Text("원칙에서 자세히 보기 ›")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.BRAND_PRIMARY)
                            .frame(minHeight: JournalDetailLayout.actionSize)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("지금은 원칙 순위 밖이에요")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(minHeight: JournalDetailLayout.actionSize)
                }
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.SUNKEN))
                    .frame(width: JournalDetailLayout.actionSize, height: JournalDetailLayout.actionSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
        .padding(.leading, JournalDetailLayout.gutter)
        .padding(.trailing, 12)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func row(_ entry: Journal) -> some View {
        let isCurrent = entry.id == currentJournalID
        let content = HStack(spacing: 16) {
            Text(JournalDetailViewModel.shortDate(entry.day))
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .frame(width: 66, alignment: .leading)
            Text(entry.displayTitle)
                .font(.system(size: 16, weight: isCurrent ? .bold : .regular))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .lineLimit(1)
            Spacer(minLength: 8)
            if isCurrent {
                Text("지금 보는 일기")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.AI_ACCENT)
            } else {
                Image("disclosure")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, JournalDetailLayout.gutter)
        .frame(height: JournalDetailLayout.sheetRowHeight)
        .background(isCurrent ? Color.AI_TINT : Color.clear)
        .contentShape(.rect)

        if isCurrent {
            content
                .accessibilityElement(children: .combine)
        } else {
            Button {
                onOpenEntry(entry)
            } label: {
                content
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

@MainActor
private func journalDetailPreviewModel() -> JournalViewModel {
    let viewModel = JournalViewModel()
    viewModel.entries = Journal.detailKeywordSamples
    viewModel.keywordStageOverride = ["경청": 1, "솔직함": 2]
    return viewModel
}

private struct JournalDetailPreview: View {
    var journal = Journal.detailSample()
    var isCommentExpanded = false
    var presentedKeyword: String?
    var startsAtBottom = false

    @StateObject private var viewModel = journalDetailPreviewModel()

    var body: some View {
        NavigationStack {
            Color.CANVAS
                .navigationDestination(isPresented: .constant(true)) {
                    JournalDetailView(
                        journal: journal,
                        journalViewModel: viewModel,
                        isCommentExpanded: isCommentExpanded,
                        presentedKeyword: presentedKeyword,
                        startsAtBottom: startsAtBottom
                    )
                }
        }
        .onAppear {
            if !viewModel.entries.contains(where: { $0.id == journal.id }) {
                viewModel.entries.insert(journal, at: 0)
            }
        }
    }
}

private let previewComment = AIText(
    text: "듣는 쪽을 택하자 문제의 진짜 모양이 보였네요. 다음 회의에는 첫 질문 하나를 미리 적어 가 보는 건 어때요?",
    engine: .appleIntelligence,
    generatedAt: .now,
    sourceJournalIDs: [],
    feedback: nil
)

#Preview("detail") {
    JournalDetailPreview()
}

#Preview("upperChipTapped") {
    JournalDetailPreview(presentedKeyword: "경청")
}

#Preview("aiCommentBelow") {
    JournalDetailPreview(
        journal: .detailSample(aiComment: previewComment),
        isCommentExpanded: true,
        startsAtBottom: true
    )
}

#Preview("tablet-detail", traits: .fixedLayout(width: 1194, height: 834)) {
    JournalDetailPreview()
}
