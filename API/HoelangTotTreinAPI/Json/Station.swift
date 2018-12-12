//
//  Station.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

public struct Coords: Codable, Equatable, Hashable {
  public let lat: Double
  public let lng: Double

  public init(lat: Double, lng: Double) {
    self.lat = lat
    self.lng = lng
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

public struct Names {
  public let lang: String
  public let middel: String
  public let kort: String
  
  public init(lang: String, middel: String, kort: String) {
    self.lang = lang
    self.middel = middel
    self.kort = kort
  }
}

extension Names: Codable, Equatable, Hashable { }

public struct Station: Equatable, Hashable, Codable {
  public let namen: Names
  public let code: String
  public let land: String
  public let lat: Double
  public let lng: Double
  public let type: StationType?
  public let radius: Double
  public let naderenRadius: Double
  public let synoniemen: [String]
  
  public var name: String {
    return namen.lang
  }
  
  public var coords: Coords {
    return Coords(lat: lat, lng: lng)
  }
}

public struct Response<ResponseType: Codable>: Codable {
  public let payload: ResponseType
}

public typealias StationsResponse = Response<Stations>
public typealias Stations = [Station]
