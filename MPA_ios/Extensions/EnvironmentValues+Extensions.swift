//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

private struct ProductRepositoryKey: EnvironmentKey {
    @MainActor
    static let defaultValue: any ProductRepositoryProtocol = ProductRepository(persistence: Persistence())
}

private struct JournalPathsKey: EnvironmentKey {
    static let defaultValue: Binding<[Product]> = .constant([])
}

extension EnvironmentValues {
    var productRepository: any ProductRepositoryProtocol {
        get { self[ProductRepositoryKey.self] }
        set { self[ProductRepositoryKey.self] = newValue }
    }

    var journalPaths: Binding<[Product]> {
        get { self[JournalPathsKey.self] }
        set { self[JournalPathsKey.self] = newValue }
    }
}

extension View {
    func productRepository(_ repository: any ProductRepositoryProtocol) -> some View {
        environment(\.productRepository, repository)
    }

    func myCustomValue(_ path: Binding<[Product]>) -> some View {
        environment(\.journalPaths, path)
    }
}
