//
//  CustomButtonData.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/16/25.
//

import Foundation

struct CustomButtonData: Equatable {
    let title: String
    let enabled: Bool

    static func == (lhs: CustomButtonData, rhs: CustomButtonData) -> Bool {
        lhs.title == rhs.title && lhs.enabled == rhs.enabled
    }
}
