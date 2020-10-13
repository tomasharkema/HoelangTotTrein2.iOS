//
//  ContentView.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 07/08/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import SwiftUI
import API
import Core

public struct MostUsedStations {
  public init(stations: Stations) {
    self.stations = stations
  }
  
  public let stations: Stations
}

struct ContentView: View {
    var body: some View {
      RootView()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView()
          .environmentObject(VariableBindable<AdvicesAndRequest?>.constant(value: nil))
          .environmentObject(VariableBindable<AdviceStations>.constant(value: AdviceStations(from: nil, to: nil)))
          .environmentObject(VariableBindable<Stations>.constant(value: []))
          .environmentObject(VariableBindable<MostUsedStations>.constant(value: MostUsedStations(stations: [])))
    }
}
#endif
