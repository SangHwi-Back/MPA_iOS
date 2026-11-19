//
//  JournalEditorRequest.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/19/26.
//

import SwiftUI

struct JournalEditorRequest: Identifiable {
    let id = UUID()
    let day: Date
    var prompt: String? = nil
}
