//
//  DailyJournalView.swift
//  MPA_ios
//
//  Created by Assistant on $(date)
//

import SwiftUI
import SwiftData
import PhotosUI

struct DailyJournalView: View {
    enum Field: Hashable {
        case title, contents
    }

    @Environment(\.dismiss) private var dismiss

    @StateObject var model: DailyJournalViewModel

    @State private var showingDatePicker = false
    @State private var showingConfirmModal = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

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
        self._model = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TitleField($model.product.name)
                DateSelector(
                    isEditMode: model.isEditMode,
                    product: $model.product)
                ContentEditor($model.product.desc)

                ImageSection()

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
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Image(systemName: "photo.badge.plus")
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
        .onChange(of: selectedPhotos) { _, newItems in
            guard newItems.isEmpty.not else { return }
            model.addImages(from: newItems)
            selectedPhotos = []
        }
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

    @ViewBuilder
    private func ImageSection() -> some View {
        if model.journalImages.isEmpty.not {
            VStack(alignment: .leading, spacing: 8) {
                TitleText("Images")

                ForEach(model.journalImages) { image in
                    ImageCard(image: image)
                }
            }
        }
    }

    private func ImageCard(image: JournalImage) -> some View {
        HStack(spacing: 12) {
            if let uiImage = UIImage(contentsOfFile: image.fileURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "Image name",
                    text: imageNameBinding(for: image)
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
            }

            Spacer()

            Button {
                model.removeImage(id: image.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
    }

    private func imageNameBinding(for image: JournalImage) -> Binding<String> {
        Binding<String>(
            get: { image.displayName },
            set: { newName in
                model.updateImageName(id: image.id, name: newName)
            }
        )
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
