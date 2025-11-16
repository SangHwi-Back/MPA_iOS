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
    @State private var showingConfirmModal = false

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
    
    init(entry: Product) {
        let vm = DailyJournalViewModel(productId: entry.id)
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
                .focused($focusedField, equals: .title)
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleField
                dateSelector
                contentEditor
                
                CustomButton(
                    data: CustomButtonData(
                        title: model.isEditMode ? "Update" : "Insert",
                        enabled: model.insertOrUpdateEnabled
                    ),
                    action: {
                        showingConfirmModal = true
                    }
                )
            }
            .padding(20)
        }
        .navigationTitle(model.isEditMode ? "Edit Journal" : "New Journal")
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

            ToolbarItemGroup(placement: .keyboard) {
                Button { movePreviousField() } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(focusedField == .title || focusedField == nil)

                Button { moveNextField() } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(focusedField == .contents)

                Spacer()

                Button("완료") {
                    focusedField = nil
                }
            }
        })
        .onTapGesture {
            focusedField = nil
        }
        .sheet(isPresented: $showingConfirmModal) {
            ConfirmationModalView(
                data: ConfirmationData(
                    title: model.product.name,
                    date: model.product.createdDate,
                    content: model.product.desc,
                    isEditMode: model.isEditMode
                ),
                onConfirm: {
                    model.saveItem()
                    dismiss()
                },
                onCancel: {
                    showingConfirmModal = false
                }
            )
        }
    }
    
    private func movePreviousField() {
        if focusedField == .title {
            focusedField = nil
        } else if focusedField == .contents {
            focusedField = .title
        }
    }
    
    private func moveNextField() {
        if focusedField == nil {
            focusedField = .title
        } else if focusedField == .title {
            focusedField = .contents
        }
    }
}

#Preview {
    DailyJournalView(entry: .init(id: 0))
}
