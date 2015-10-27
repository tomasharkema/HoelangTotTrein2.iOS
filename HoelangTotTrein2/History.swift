//
//  History.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 02-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import CoreDataKit

enum HistoryType: Int {
  case From = 0
  case To = 1
}

class History: NSManagedObject, NamedManagedObject {
  static var entityName = "History"
}
