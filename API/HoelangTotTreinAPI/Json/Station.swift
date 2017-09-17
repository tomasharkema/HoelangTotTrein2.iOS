//
//  Station.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

public struct Coords: Codable {
  public let lat: Double
  public let lon: Double

  public init(lat: Double, lon: Double) {
    self.lat = lat
    self.lon = lon
  }
}

public enum StationType: String, Codable {
  case MegaStation = "megastation"
  case KnooppuntIntercityStation = "knooppuntIntercitystation"
  case KnooppuntSneltreinStation = "knooppuntSneltreinstation"
  case KnooppuntStoptreinStation = "knooppuntStoptreinstation"
  case IntercityStation = "intercitystation"
  case SneltreinStation = "sneltreinstation"
  case StoptreinStation = "stoptreinstation"
  case FacultatiefStation = "facultatiefStation"
}

public struct Station: Equatable, Hashable, Codable {
  public let name: String
  public let code: String
  public let land: String
  public let coords: Coords
  public let type: StationType?
}

public func ==(lhs: Station, rhs: Station) -> Bool {
  return lhs.code == rhs.code
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
