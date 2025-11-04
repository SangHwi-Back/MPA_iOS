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
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var model: DailyJournalViewModel
    
    @State private var showingDatePicker = false
    
    @FocusState private var focusedField: Field?
    
    private var shouldShowPlaceholder: Bool {
        model.product.desc
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        && focusedField != .contents
    }
    
    private var isSubmitEnable: Bool {
        model.product.name.isNotEmpty
        && model.product.desc.isNotEmpty
    }
    
    init(entry: Product? = nil) {
        let vm = DailyJournalViewModel(productId: entry?.id ?? 0)
        self._model = Binding.constant(vm)
    }
    
    private var TitleText: (String) -> Text = { text in
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Title")
            
            TextField("Enter your journal title", text: $model.product.name)
                .textFieldStyle(.plain)
                .padding(16)
                .glassEffect()
                .shadow(radius: 3)
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
                    
                    Text(model.isEditMode ? model.product.createdDate : model.product.updatedDate ?? Date(), style: .date)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .glassEffect()
                .shadow(radius: 3)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $model.product.createdDate,
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
                
                TextEditor(text: $model.product.desc)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .glassEffect(in: .rect(cornerRadius: 12))
                    .shadow(radius: 3)
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
            title: model.isEditMode ? "Update" : "Insert",
            action: {
                model.saveItem()
                dismiss()
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
        .navigationTitle(model.isEditMode ? "Edit Entry" : "New Entry")
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.immediately)
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
    let backgroundColor: Color?
    let action: () -> Void
    
    init(title: String, backgroundColor: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .if(backgroundColor != nil, transform: {
                    $0.background(backgroundColor!)
                })
                .if(backgroundColor == nil, transform: {
                    $0.glassEffect()
                })
                .shadow(radius: 3)
        }
    }
}

#Preview {
    DailyJournalView()
}
