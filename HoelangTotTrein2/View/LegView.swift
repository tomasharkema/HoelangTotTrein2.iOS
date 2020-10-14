//
//  LegView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct LegView: View {
  var leg: Leg

  var body: some View {
    HStack(alignment: .center) {
      Image("connection")
      VStack(spacing: 7) {
        LegPlaceView(legPlace: leg.origin)
        LegPlaceView(legPlace: leg.destination)
      }
    }
  }
}
