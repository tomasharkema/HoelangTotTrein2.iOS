//
//  DelayTextView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct DelayTextView: View {
  var legPlace: LegPlace

  private var offset: String? {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute]
    let delay = legPlace.time.delay
    return delay.flatMap { formatter.string(from: $0) }
  }

  @ViewBuilder
  var body: some View {
    if let offset = offset {
      Text("+ \(offset)m")
        .foregroundColor(Color.red)
    } else {
      EmptyView()
    }
  }
}
