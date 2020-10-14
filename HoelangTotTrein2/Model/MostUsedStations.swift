//
//  MostUsedStations.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 14/10/2020.
//  Copyright © 2020 Tomas Harkema. All rights reserved.
//

import API
import Foundation

public struct MostUsedStations {
  public init(stations: Stations) {
    self.stations = stations
  }

  public let stations: Stations
}
