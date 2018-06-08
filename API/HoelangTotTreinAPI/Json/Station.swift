//
//  Station.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

public struct Coords: Codable, Equatable {
  public let lat: Double
  public let lon: Double

  public init(lat: Double, lon: Double) {
    self.lat = lat
    self.lon = lon
  }
}

public enum StationType: String, Codable, Equatable {
  case megaStation = "megastation"
  case knooppuntIntercityStation = "knooppuntIntercitystation"
  case knooppuntSneltreinStation = "knooppuntSneltreinstation"
  case knooppuntStoptreinStation = "knooppuntStoptreinstation"
  case intercityStation = "intercitystation"
  case sneltreinStation = "sneltreinstation"
  case stoptreinStation = "stoptreinstation"
  case facultatiefStation = "facultatiefStation"
}

public struct Station: Equatable, Hashable, Codable {
  public let name: String
  public let code: String
  public let land: String
  public let coords: Coords
  public let type: StationType?

  init(name: String, code: String, land: String, coords: Coords, type: StationType?) {
    self.name = name
    self.code = code
    self.land = land
    self.coords = coords
    self.type = type
  }

}

public struct StationsResponse: Codable {
  public let stations: [Station]
}

extension Station {
  public var hashValue: Int {
    return name.hashValue
  }
}

public typealias Stations = [Station]
