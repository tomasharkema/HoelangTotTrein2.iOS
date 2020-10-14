//
//  CrowdForecastView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct CrowdForecastView: View {
  let crowdForecast: CrowdForecast?

  func image(name: String) -> some View {
    Image(systemName: name)
      .resizable()
      .frame(width: 5, height: 10)
  }

  var fullBars: Int {
    crowdForecast?.fullBars ?? 0
  }

  var color: Color {
    crowdForecast?.color ?? .gray
  }

  var body: some View {
    HStack(spacing: 3) {
      if crowdForecast == nil || crowdForecast == .unknown {
        EmptyView()
      } else {
        ForEach(0 ..< fullBars) { _ in
          self.image(name: "rectangle.fill")
            .foregroundColor(self.color)
        }

        ForEach(0 ..< (3 - fullBars)) { _ in
          self.image(name: "rectangle")
            .foregroundColor(.gray)
        }
      }
    }
  }
}

extension CrowdForecast {
  var fullBars: Int {
    switch self {
    case .high:
      return 3
    case .medium:
      return 2
    case .low:
      return 1
    case .unknown:
      return 0
    }
  }

  var color: Color {
    switch self {
    case .high:
      return .red
    case .medium:
      return .orange
    case .low:
      return .green
    case .unknown:
      return .gray
    }
  }
}
