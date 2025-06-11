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
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker = false
    
    @FocusState private var focusedField: Field?
    
    private let existingEntry: Product?
    private let isEditing: Bool
    
    init(entry: Product? = nil) {
        self.existingEntry = entry
        self.isEditing = entry != nil
        
        if let entry = entry {
            _title = State(initialValue: entry.name)
            _content = State(initialValue: entry.desc)
            _selectedDate = State(initialValue: entry.date ?? Date())
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter your journal title", text: $title)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            Text("Content")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                
                TextEditor(text: $content)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(minHeight: 150)
                    .focused($focusedField, equals: .contents)
                
                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && focusedField != .contents {
                    Text("Write about your day...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            CustomButton(title: "Cancel", backgroundColor: Color(.systemGray5), action: {
                dismiss()
            })
            
            CustomButton(
                title: isEditing ? "Update" : "Insert",
                backgroundColor: title.isEmpty || content.isEmpty ? Color.gray : Color.blue,
                action: {
                    // TODO: Save Data
                }
            )
            .disabled(title.isEmpty || content.isEmpty)
        }
    }
    
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
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        }
    }
}

#Preview {
    DailyJournalView()
} 
