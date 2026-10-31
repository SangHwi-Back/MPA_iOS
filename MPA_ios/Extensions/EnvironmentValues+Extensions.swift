//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    // @Entry의 기본값은 nonisolated 컨텍스트에서 평가되므로, 메인 액터에서 호출됨을 명시해 생성합니다.
    // 실제 저장소는 MPA_iosApp 에서 `.productRepository(_:)` 로 주입합니다.
    @Entry var productRepository: any ProductRepositoryProtocol = MainActor.assumeIsolated { () -> any ProductRepositoryProtocol in
        MockProductRepository()
    }
    @Entry var journalPaths: Binding<[Product]> = .constant([])
    @Entry var contentsEnvironment: ContentsEnvironment = .generalVertical
}

extension View {
    func productRepository(_ repository: any ProductRepositoryProtocol) -> some View {
        environment(\.productRepository, repository)
    }

    func myCustomValue(_ path: Binding<[Product]>) -> some View {
        environment(\.journalPaths, path)
    }
}
