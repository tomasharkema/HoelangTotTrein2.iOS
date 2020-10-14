//
//  LegPlaceView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import SwiftUI

struct LegPlaceView: View {
  let legPlace: LegPlace

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      FareTimeView(fareTime: legPlace.time)
      Text(legPlace.name)
        .font(Font.headline.bold())
      DelayTextView(legPlace: legPlace)

      Spacer()

      TrackView(plannedTrack: legPlace.plannedTrack, actualTrack: legPlace.actualTrack)
        .font(Font.body)
    }
  }
}
