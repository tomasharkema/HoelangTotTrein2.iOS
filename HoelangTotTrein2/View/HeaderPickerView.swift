//
//  HeaderPickerView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Core
import Foundation
import SwiftUI

struct HeaderPickerView: View {
  @EnvironmentObject var adviceStations: VariableBindable<AdviceStations>

  var body: some View {
    HStack {
      Button(action: {
        _ = App.travelService.travelFromCurrentLocation()
      }) {
        Image(systemName: "location").padding()
      }.foregroundColor(Color.white)
      VStack(alignment: .leading) {
        StationPicker(picker: .from, stationName: self.adviceStations.value.from)
          .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
        StationPicker(picker: .to, stationName: self.adviceStations.value.to)
          .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))

      }.padding([.top, .bottom])
      Spacer()
      Button(action: {
        App.travelService.switchFromTo()
      }) {
        Image(systemName: "arrow.up.arrow.down").padding()
      }.foregroundColor(Color.white)

    }.background(Color.black.opacity(0.6))
  }
}
