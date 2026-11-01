//
//  DateFormatter+Extensions.swift
//  MPA_ios
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

extension DateFormatter {
    static let common: DateFormatter = {
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
#else
        return ISO8601DateFormatter.common
#endif
    }()
}
