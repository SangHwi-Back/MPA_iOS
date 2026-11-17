//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalEditorView.swift
//  MPA_ios
//

import SwiftUI

/// 일기 작성/저장 화면. 디자인 시안(1.png = 새 일기, 2.png = 저장됨, 3.png = 날짜 선택)을 따른다.
/// 저장 전에는 "완료" 버튼으로 `JournalViewModel.addJournal`을 1회 호출해 저장하고,
/// 저장 후에는 저장 시각을 보여주는 상태로 전환된다 (서버/DB가 없어 이후 수정은 반영되지 않음).
struct JournalEditorView: View {
    private var onClose: () -> Void
    
    @State private var day: Date
    @State private var pendingDate: Date
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var prompt: String?
    @State private var showDatePicker = false
    @State private var journal: Journal
    @State private var mode: JournalEditorViewMode = .write
    
    @Environment(JournalViewModel.self) private var journalViewModel
    
    init(initialDate: Date? = nil, initialPrompt: String? = nil, onClose: @escaping () -> Void) {
        self.onClose = onClose
        let startDay = Calendar.current.startOfDay(for: initialDate ?? .now)
        _day = State(initialValue: startDay)
        _pendingDate = State(initialValue: startDay)
        _prompt = State(initialValue: initialPrompt)
        _journal = State(initialValue: Journal(day: startDay, prompt: initialPrompt))
    }
    
    private var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    dateField
                    
                    if let prompt {
                        promptChip(prompt)
                    }
                    
                    titleField
                    bodyField
                    
                    if !journal.visibleKeywords.isEmpty {
                        keywordsSection(journal.visibleKeywords)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            bottomToolbar
        }
        .background(Color.CANVAS)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onAppear {
            // A journal already written on this day opens in edit mode.
            if let existing = journalViewModel.journal(on: day) {
                journal = existing
                title = existing.title
                bodyText = existing.body
                prompt = existing.prompt ?? prompt
                mode = .edit
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                save()
                onClose()
            } label: {
                Text("완료")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isEmpty ? Color.TEXT_TERTIARY : Color.BRAND_ON_PRIMARY)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(isEmpty ? Color.SUNKEN : Color.BRAND_PRIMARY))
            }
            .buttonStyle(.plain)
            .disabled(isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    /// Copies the edits into `journal` and stores it.
    private func save() {
        journal.day = day
        journal.title = title
        journal.body = bodyText
        journal.prompt = prompt
        if mode == .edit {
            journal.editedAt = .now
        }
        journalViewModel.save(journal)
    }
    
    // MARK: - Date field
    
    private var dateField: some View {
        Button {
            pendingDate = day
            showDatePicker = true
        } label: {
            HStack(spacing: 4) {
                Text(formattedDate(day))
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.BRAND_PRIMARY)
        }
        .buttonStyle(.plain)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let dayNumber = cal.component(.day, from: date)
        let weekdayNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
        let idx = cal.component(.weekday, from: date) - 1
        return "\(month)월 \(dayNumber)일 \(weekdayNames[idx % 7])"
    }
    
    // MARK: - AI prompt chip
    
    private func promptChip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(Color.AI_ACCENT)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.BRAND_ON_CONTAINER)
            Spacer()
            Button {
                prompt = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.BRAND_ON_CONTAINER)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.BRAND_CONTAINER)
        )
    }
    
    // MARK: - Title & body
    
    private var titleField: some View {
        TextField("", text: $title, prompt: Text("오늘의 제목").foregroundStyle(Color.TEXT_TERTIARY))
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.TEXT_PRIMARY)
            .textFieldStyle(.plain)
    }
    
    private var bodyField: some View {
        ZStack(alignment: .topLeading) {
            if bodyText.isEmpty {
                Text("떠오르는 대로 몇 줄 적어보세요.")
                    .font(.body)
                    .foregroundStyle(Color.TEXT_TERTIARY)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: $bodyText)
                .font(.body)
                .foregroundStyle(Color.TEXT_PRIMARY)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 280)
        }
    }
    
    // MARK: - Keywords (shown only once the entry has been analyzed)
    
    private func keywordsSection(_ keywords: [JournalKeyword]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.AI_ACCENT)
                Text("이 일기에서 발견한 키워드")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.AI_ACCENT)
            }
            HStack(spacing: 8) {
                ForEach(keywords, id: \.name) { keyword in
                    Text(keyword.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.TEXT_PRIMARY)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.SUNKEN))
                }
            }
        }
    }
    
    // MARK: - Bottom toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            Image(systemName: "photo")
                .foregroundStyle(Color.TEXT_SECONDARY)
            Image(systemName: "mic")
                .foregroundStyle(Color.TEXT_SECONDARY)
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("글감")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.BRAND_ON_CONTAINER)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.BRAND_CONTAINER))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.CONTAINER)
    }
    
    // MARK: - Date picker sheet
    
    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("날짜 선택", selection: $pendingDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.BRAND_PRIMARY)
                .padding()
                .navigationTitle("날짜 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { showDatePicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("확인") {
                            day = Calendar.current.startOfDay(for: pendingDate)
                            showDatePicker = false
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

enum JournalEditorViewMode {
case write, edit
}

#Preview {
    JournalEditorView(onClose: {})
        .environment(JournalViewModel(repository: InMemoryJournalRepository()))
}
