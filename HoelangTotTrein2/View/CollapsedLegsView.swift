//
//  CollapsedLegsView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct CollapsedLegsView: View {
  let legs: [Leg]

  private func single() -> some View {
    VStack {
      LegPlaceView(legPlace: legs.first!.origin)
      LegPlaceView(legPlace: legs.first!.destination)
    }
  }

  private func multiple() -> some View {
    VStack(alignment: .leading) {
      LegPlaceView(legPlace: legs.first!.origin)
      ForEach(legs.dropLast().dropFirst(), id: \.name) { leg in
        LegPlaceView(legPlace: leg.origin)
      }
      LegPlaceView(legPlace: legs.last!.destination)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if legs.count > 1 {
        multiple()
      } else {
        single()
      }
    }
  }
}
