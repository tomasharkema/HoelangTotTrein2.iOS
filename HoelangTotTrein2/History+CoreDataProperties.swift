//
//  History+CoreDataProperties.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 02-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension History {

  @NSManaged var date: NSDate?
  @NSManaged private var type: NSNumber?
  @NSManaged var station: StationRecord?

  var historyType: HistoryType! {
    get {
      return HistoryType(rawValue: type!.integerValue)
    }
    set {
      type = newValue!.rawValue
    }
  }
}
