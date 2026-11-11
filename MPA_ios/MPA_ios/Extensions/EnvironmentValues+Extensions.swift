//
//  EnvironmentValues+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 7/27/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var journalPaths: Binding<[Product]> = .constant([])
    @Entry var contentsEnvironment: ContentsEnvironment = .generalVertical
    @Entry var isDeviceiPad: Bool = false
    @Entry var isDeviceiPhoneDuo: Bool = false
    @Entry var hingeStatus: DeviceHingeStatus? = nil
}

enum ContentsEnvironment {
    case navigationSplit
    /// iPhone Duo Split + 가로
    case horizontalDuoSplit
    /// iPhone Duo 오버레이 + 세로
    case verticalDuoOverlay
    /// iPhone 세로 형태 기준
    case generalVertical
}

enum DeviceHingeStatus {
    case closed
    case partiallyOpen
    case fullyOpen
}
