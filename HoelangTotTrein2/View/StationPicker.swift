//
//  StationPicker.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Core
import Foundation
import SwiftUI

struct StationPicker: View {
  let picker: PickerState
  let stationName: String?

  @State var showStationList: Bool = false
  @EnvironmentObject var stations: VariableBindable<Stations>
  @EnvironmentObject var mostUsedStations: VariableBindable<MostUsedStations>

  var body: some View {
    HStack(alignment: .lastTextBaseline) {
      Text("\(picker.description):")
        .foregroundColor(Color.white)
        .font(Font.footnote)
      Button(action: {
        self.showStationList.toggle()
      }) {
        Text(stationName ?? "[Pick Station]")
          .foregroundColor(Color.white)
          .font(Font.system(size: 21).bold())
      }
    }.sheet(isPresented: $showStationList, onDismiss: nil) {
      StationsList(picker: self.picker, showStationList: self.$showStationList)
        .environmentObject(self.stations)
        .environmentObject(self.mostUsedStations)
    }
  }
}
