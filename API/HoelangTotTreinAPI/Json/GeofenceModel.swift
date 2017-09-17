//
//  GeofenceModel.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

public enum GeofenceType: String, Codable {
  case start = "start"
  case overstap = "overstap"
  case end = "end"

  case tussenStation = "tussenstation"
}

public struct GeofenceModel: Equatable, Codable {
  public let type: GeofenceType
  public let stationName: String
  public let fromStop: Stop?
  public let toStop: Stop?

  public init(type: GeofenceType, stationName: String, fromStop: Stop?, toStop: Stop?) {
    self.type = type
    self.stationName = stationName
    self.fromStop = fromStop
    self.toStop = toStop
  }
}

public func ==(lhs: GeofenceModel, rhs: GeofenceModel) -> Bool {
  return lhs.type == rhs.type &&
    lhs.stationName == rhs.stationName &&
    lhs.fromStop == rhs.fromStop &&
    lhs.toStop == rhs.toStop
}

public struct GeofenceModels {
  var geofenceModels: [GeofenceModel]
}

