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

enum StationType: String {
  case MegaStation = "megastation"
  case KnooppuntIntercityStation = "knooppuntIntercitystation"
  case KnooppuntSneltreinStation = "knooppuntSneltreinstation"
  case KnooppuntStoptreinStation = "knooppuntStoptreinstation"
  case IntercityStation = "intercitystation"
  case SneltreinStation = "sneltreinstation"
  case StoptreinStation = "stoptreinstation"
  case FacultatiefStation = "facultatiefStation"
}

struct Station: Equatable, Hashable {
  let name: String
  let code: String
  let land: String
  let coords: Coords
  let type: StationType
}

func ==(lhs: Station, rhs: Station) -> Bool {
  return lhs.code == rhs.code
}

struct StationsResponse {
  let stations: [Station]
}

extension Station {
  var hashValue: Int {
    return name.hashValue
  }
}