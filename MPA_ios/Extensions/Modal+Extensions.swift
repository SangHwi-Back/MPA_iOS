//
//  Modal+Extensions.swift
//  MPA_ios
//
//  Created by 백상휘 on 2/16/26.
//

import SwiftUI

@Observable
final class ModalState {
    var modalType: ModalType = .none
}

@MainActor
private struct ShowModalKey: @preconcurrency EnvironmentKey {
    static let defaultValue: ModalState = .init()
}

extension EnvironmentValues {
    var showModal: ModalState {
        get { self[ShowModalKey.self] }
        set { self[ShowModalKey.self] = newValue }
    }
}
