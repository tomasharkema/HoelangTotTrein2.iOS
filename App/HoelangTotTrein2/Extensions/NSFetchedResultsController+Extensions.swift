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

  func optionalObjectAtIndexPath(_ indexPath: IndexPath) -> Any? {
    if let objects = sections?[indexPath.section].objects, indexPath.row < objects.count {
      return objects[indexPath.row]
    }

    return nil
  }
  
}

//func fetchedRequest(_ objects: [NSManagedObject]) -> NSFetchRequest? {
//  if let object = objects.first {
//
//    let predicate = NSPredicate(format: objects
//      .map { $0.objectID }
//      .reduce("") { prev, element in
//        if prev == "" {
//          return prev + "(SELF = %@)"
//        } else {
//          return prev + " OR (SELF = %@)"
//        }
//      }, argumentArray: objects.map { $0.objectID })
//
//
////    let sortDescriptor = NSSortDescriptor(key: "name", ascending: true) { (lhs, rhs) -> NSComparisonResult in
////      print(lhs, rhs)
////      return NSComparisonResult.OrderedDescending
////    }
//
//    let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
//
//    return object.managedObjectContext?.createFetchRequest(object.entity, predicate: predicate, sortDescriptors: [sortDescriptor])
//  }
//
//  return nil
//}
