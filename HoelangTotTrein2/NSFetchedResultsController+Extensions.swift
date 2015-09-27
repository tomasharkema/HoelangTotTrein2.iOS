//
//  NSFetchedResultsController+Extensions.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData

extension NSFetchedResultsController {

  func optionalObjectAtIndexPath(indexPath: NSIndexPath) -> AnyObject? {
    if let objects = sections?[indexPath.section].objects where indexPath.row < objects.count {
      return objects[indexPath.row]
    }

    return nil
  }
  
}