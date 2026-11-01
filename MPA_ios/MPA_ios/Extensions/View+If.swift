//
//  View+If.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/11/25.
//

import SwiftUI

extension View {
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
