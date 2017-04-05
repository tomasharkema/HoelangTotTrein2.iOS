//
//  GeofenceModel.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

enum GeofenceType: String {
  case start = "start"
  case overstap = "overstap"
  case end = "end"

  case tussenStation = "tussenstation"
}

struct GeofenceModel: Equatable {
  let type: GeofenceType
  let stationName: String
  let fromStop: Stop?
  let toStop: Stop?
}

func ==(lhs: GeofenceModel, rhs: GeofenceModel) -> Bool {
  return lhs.type == rhs.type &&
    lhs.stationName == rhs.stationName &&
    lhs.fromStop == rhs.fromStop &&
    lhs.toStop == rhs.toStop
}

struct GeofenceModels {
  var geofenceModels: [GeofenceModel]
}

