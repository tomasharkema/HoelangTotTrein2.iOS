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
    return Station(name: name, code: code, land: land, coords: Coords(lat: lat.doubleValue, lon: lon.doubleValue), type: StationType(rawValue: type)!)
  }

  var historyUsed: NSNumber {
    do {
      return try managedObjectContext?.find(History.self, predicate: NSPredicate(format: "station = %@", self)).count ?? 0
    } catch {
      return 0
    }
  }

  var firstLetterUpperCase: String {
    return name.substringWithRange(name.startIndex..<name.characters.index(name.startIndex, offsetBy: 1)).uppercased()
  }
}
