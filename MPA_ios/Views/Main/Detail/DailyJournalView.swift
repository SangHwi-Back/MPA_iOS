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
    
    init(repository: ProductRepositoryProtocol, entry: Product) {
        let vm = DailyJournalViewModel(
            repository: repository,
            productId: entry.id)
        self._model = Binding.constant(vm)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TitleField($model.product.name)
                DateSelector(
                    isEditMode: model.isEditMode,
                    product: $model.product)
                ContentEditor($model.product.desc)
                
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
        .onTapGesture { focusedField = nil }
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
                onCancel: { showingConfirmModal = false }
            )
        }
    }
    
    private var TitleText: (String) -> Text = { text in
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private func TitleField(_ name: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Title")
            
            TextField("Enter your journal title", text: name)
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain)
                .padding(16)
                .glassEffect(.regular.interactive())
        }
    }
    
    private func DateSelector(isEditMode: Bool, product: Binding<Product>) -> some View {
        let _product = product.wrappedValue
        let dateText = isEditMode ? _product.createdDate : _product.updatedDate
        return VStack(alignment: .leading, spacing: 8) {
            TitleText("Date")
            
            ZStack {
                Button {
                    showingDatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        
                        Text(dateText ?? Date(), style: .date)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                }
            }
            .glassEffect(.regular.interactive())
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: product.createdDate,
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
    
    private func ContentEditor(_ desc: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleText("Content")
            
            ZStack(alignment: .topLeading) {
                
                TextEditor(text: desc)
                    .padding(.horizontal, 12)
                    .scrollDisabled(true)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .contents)
                    .frame(minHeight: 150)
                
                if shouldShowPlaceholder {
                    Text("Write about your day...")
                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
            }
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
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
    DailyJournalView(
        repository: MockProductRepository(withSampleData: false),
        entry: Product(id: 0)
    )
}
