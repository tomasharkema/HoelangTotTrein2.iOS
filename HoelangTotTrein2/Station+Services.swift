//
//  Station+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 02-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import CoreDataKit
import CoreLocation

extension Station {
  func getStationRecord(context: NSManagedObjectContext) -> StationRecord? {
    do {
      return try context.findFirst(StationRecord.self, predicate: NSPredicate(format: "code = %@", code))
    } catch {
      print(error)
      return nil
    }
  }

  static func fromCode(code: String, context: NSManagedObjectContext = CDK.mainThreadContext) -> Station? {
    let toPredicate = NSPredicate(format: "code = %@", code)
    do {
      return try context.findFirst(StationRecord.self, predicate: toPredicate)?.toStation()
    } catch {
      return nil
    }
  }
}


extension Coords {
  var location: CLLocation {
    return CLLocation(latitude: lat, longitude: lon)
  }
}
