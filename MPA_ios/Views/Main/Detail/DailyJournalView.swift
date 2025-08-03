//
//  DailyJournalView.swift
//  MPA_ios
//
//  Created by Assistant on $(date)
//

import SwiftUI
import SwiftData

struct DailyJournalView: View {
    enum Field: Hashable {
        case title, contents
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.journalPaths) private var journalPaths
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker = false
    
    @FocusState private var focusedField: Field?
    
    private let existingEntry: Product?
    private let isEditing: Bool
    private var shouldShowPlaceholder: Bool {
        content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        && focusedField != .contents
    }
    
    private var isSubmitEnable: Bool {
        title.isNotEmpty && content.isNotEmpty
    }
    
    init(entry: Product? = nil) {
        self.existingEntry = entry
        self.isEditing = entry != nil
        
        if let entry = entry {
            _title = State(initialValue: entry.name)
            _content = State(initialValue: entry.desc)
            _selectedDate = State(initialValue: entry.date ?? Date())
        }
    }
    
    private var TitleText: (String) -> Text = { text in
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Title")
            
            TextField("Enter your journal title", text: $title)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(.systemGray6))
                .localRoundedShadowed()
        }
    }
    
    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Date")
            
            Button {
                showingDatePicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text(selectedDate, style: .date)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .localRoundedShadowed()
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Content")
            
            ZStack(alignment: .topLeading) {
                
                TextEditor(text: $content)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .localRoundedShadowed()
                    .focused($focusedField, equals: .contents)
                    .frame(minHeight: 150)
                
                if shouldShowPlaceholder {
                    Text("Write about your day...")
                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
            }
        }
    }
    
    private var actionButtons: some View {
        CustomButton(
            title: isEditing ? "Update" : "Insert",
            backgroundColor: isSubmitEnable ? Color.blue : Color(.systemGray4),
            action: {
                // TODO: Save Data
            }
        )
        .disabled(!isSubmitEnable)
    }
    
    static let nonMutableDependency = 5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleField
                dateSelector
                contentEditor
                actionButtons
            }
            .padding(20)
        }
        .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color(.systemGray3))
                }
            }
        })
        .onTapGesture {
            focusedField = nil
        }
    }
}

private struct CustomButton: View {
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(backgroundColor)
                .localRoundedShadowed()
        }
    }
}

private struct LocalRoundedShadowViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

private extension View {
    func localRoundedShadowed() -> some View {
        modifier(LocalRoundedShadowViewModifier())
    }
}

#Preview {
    DailyJournalView()
}
