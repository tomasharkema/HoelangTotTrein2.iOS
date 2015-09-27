//
//  StationRecord.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import CoreDataKit

class StationRecord: NSManagedObject, NamedManagedObject {
  static var entityName = "StationRecord"

  func toStation() -> Station {
    return Station(name: name, code: code, land: land, coords: Coords(lat: lat.doubleValue, lon: lon.doubleValue))
  }
}
