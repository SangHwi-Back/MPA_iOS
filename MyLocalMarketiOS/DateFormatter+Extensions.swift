//
//  DateFormatter+Extensions.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation

extension ISO8601DateFormatter {
    static let common: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
