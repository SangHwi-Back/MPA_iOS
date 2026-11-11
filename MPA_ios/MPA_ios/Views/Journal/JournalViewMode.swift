//
//  JournalViewMode.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//


import SwiftUI

enum JournalViewMode: String, CaseIterable {
    
    static let viewModeKey = "journal.viewMode"
    
    case list
    case calendar

    var title: String {
        switch self {
        case .list:     return "리스트"
        case .calendar: return "캘린더"
        }
    }
    
    static func storedViewMode() -> JournalViewMode {
        UserDefaults.standard.string(forKey: viewModeKey).flatMap(JournalViewMode.init(rawValue:)) ?? .list
    }
}
