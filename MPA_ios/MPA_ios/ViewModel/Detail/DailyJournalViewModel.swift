//
//  DailyJournalViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 8/3/25.
//

import Foundation
import SwiftData
import SwiftUI
import PhotosUI

@MainActor
class DailyJournalViewModel: ObservableObject {
    private(set) var isEditMode: Bool = false

    @Environment(\.journalPaths) private var journalPaths
    private var repository: ProductRepositoryProtocol

    private var productId: Int
    @Binding var product: Product

    @Published var journalImages: [JournalImage] = []

    var insertOrUpdateEnabled: Bool {
        product.name.isEmpty.not && product.desc.isEmpty.not
    }

    init(repository: any ProductRepositoryProtocol, productId: Int) {
        self.productId = productId
        self.repository = repository

        do {
            let product = try self.repository.fetch(id: productId)

            if let item = product {
                self._product = .constant(item)
                isEditMode = true
            }
            else {
                self._product = .constant(Product(id: productId))
                isEditMode = false
            }
        } catch {
            fatalError("Error message: \(error)")
        }

        loadImages()
    }

    private func loadImages() {
        journalImages = product.images.compactMap { JournalImage.from(jsonString: $0) }
    }

    func addImages(from items: [PhotosPickerItem]) {
        let dir = JournalImage.imagesDirectoryURL
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        for item in items {
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }

                let imageData: Data
                if let uiImage = UIImage(data: data) {
                    imageData = uiImage.jpegData(compressionQuality: 0.8) ?? data
                } else {
                    imageData = data
                }

                let journalImage = JournalImage()
                let fileURL = journalImage.fileURL

                try? imageData.write(to: fileURL)

                journalImages.append(journalImage)
                syncImagesToProduct()
            }
        }
    }

    func updateImageName(id: UUID, name: String) {
        guard let index = journalImages.firstIndex(where: { $0.id == id }) else { return }

        let oldImage = journalImages[index]
        let oldURL = oldImage.fileURL

        let newFileName = JournalImage.buildFileName(id: oldImage.id, displayName: name)
        let newURL = JournalImage.imagesDirectoryURL.appendingPathComponent(newFileName)

        if FileManager.default.fileExists(atPath: oldURL.path) && oldURL != newURL {
            try? FileManager.default.moveItem(at: oldURL, to: newURL)
        }

        journalImages[index].displayName = name
        journalImages[index].fileName = newFileName
        syncImagesToProduct()
    }

    func removeImage(id: UUID) {
        guard let index = journalImages.firstIndex(where: { $0.id == id }) else { return }

        let image = journalImages[index]
        let fileURL = image.fileURL

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        journalImages.remove(at: index)
        syncImagesToProduct()
    }

    private func syncImagesToProduct() {
        product.images = journalImages.compactMap { $0.toJSONString() }
    }

    func saveItem() {
        guard isEditMode.not else {
#if DEBUG
            do { try repository.update(product) } catch {
                fatalError(error.localizedDescription)
            }
#else
            try? repository.update(product)
#endif
            return
        }

#if DEBUG
        do { try repository.save(product) } catch {
            fatalError(error.localizedDescription)
        }
#else
        try? repository.save(product)
#endif
    }
}
