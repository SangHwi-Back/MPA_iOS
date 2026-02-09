//
//  MainDateListLabel.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

struct MainDateListLabel: View {
    @State private var isPressed: Bool = false
    let product: Product

    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        let date = product.createdDate

        let sameYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
        let sameMonth = calendar.isDate(date, equalTo: now, toGranularity: .month)
        let sameWeek = calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        if sameWeek {
            formatter.dateFormat = "EEEE"
        } else if sameMonth {
            formatter.dateFormat = "d일"
        } else if sameYear {
            formatter.dateFormat = "M월 d일"
        } else {
            formatter.dateFormat = "yyyy년 M월 d일"
        }

        return formatter.string(from: date)
    }

    private var displayText: String {
        if product.name.isEmpty {
            return formattedDate
        } else {
            return "\(product.name) \(formattedDate)"
        }
    }

    var body: some View {
        Text(displayText)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .glassEffect(.regular.interactive(), in: Capsule())
    }
}

#Preview {
    ScrollView {
        MainDateListLabel(product: Product(id: 1))
    }
    .background(Color.black)
}
