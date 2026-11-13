//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var journalPaths: Binding<[Product]> = .constant([])
    @Entry var hingeStatus: DeviceHingeStatus? = nil
}

enum DeviceHingeStatus {
    case closed
    case partiallyOpen
    case fullyOpen
}
