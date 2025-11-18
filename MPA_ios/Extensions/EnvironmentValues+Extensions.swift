//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var productRepository: ProductRepository = ProductRepository(persistence: Persistence())
    @Entry var journalPaths: Binding<[Product]> = .constant([])
}

extension View {
    func productRepository(_ repository: ProductRepository) -> some View {
        environment(\.productRepository, repository)
    }

    func myCustomValue(_ path: Binding<[Product]>) -> some View {
        environment(\.journalPaths, path)
    }
}
