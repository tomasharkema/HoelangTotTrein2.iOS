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
  public let uicCode: UicCode
  public let stop: Stop
  
  public init(type: GeofenceType, uicCode: UicCode, stop: Stop) {
    self.type = type
    self.uicCode = uicCode
    self.stop = stop
  }
}

public struct GeofenceModels {
  var geofenceModels: [GeofenceModel]
}

