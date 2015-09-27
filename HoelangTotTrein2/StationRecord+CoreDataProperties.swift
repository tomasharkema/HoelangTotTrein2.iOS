//
//  StationRecord+CoreDataProperties.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension StationRecord {

  @NSManaged var name: String
  @NSManaged var code: String
  @NSManaged var land: String
  @NSManaged var lat: NSNumber
  @NSManaged var lon: NSNumber
}
