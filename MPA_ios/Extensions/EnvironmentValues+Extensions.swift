//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var journalPaths: [Product] = []
}

extension View {
    func myCustomValue(_ str: String) -> some View {
        environment(\.journalPaths, [])
    }
}
