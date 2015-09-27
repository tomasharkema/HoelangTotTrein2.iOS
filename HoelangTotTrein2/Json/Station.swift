//
//  Station.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct Coords {
  let lat: Double
  let lon: Double
}

struct Station {
  let name: String
  let code: String
  let land: String
  let coords: Coords
}

struct StationsResponse {
  let stations: [Station]
}