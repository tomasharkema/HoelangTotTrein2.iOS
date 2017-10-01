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
  public let stop: Stop
  
  public init(type: GeofenceType, stationName: String, stop: Stop) {
    self.type = type
    self.stationName = stationName
    self.stop = stop
  }
}

public func ==(lhs: GeofenceModel, rhs: GeofenceModel) -> Bool {
  return lhs.type == rhs.type &&
    lhs.stationName == rhs.stationName &&
    lhs.stop == rhs.stop
}

public struct GeofenceModels {
  var geofenceModels: [GeofenceModel]
}

