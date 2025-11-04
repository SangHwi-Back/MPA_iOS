//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var journalPaths: Binding<[Product]> = .constant([])
}

extension View {
    func myCustomValue(_ path: Binding<[Product]>) -> some View {
        environment(\.journalPaths, path)
    }
}
