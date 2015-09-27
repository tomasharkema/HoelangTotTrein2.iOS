//
//  StationFetchedResultController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData

class StationFetchedResultControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
  var sectionAnimation: UITableViewRowAnimation = .Fade
  var rowAnimation: UITableViewRowAnimation = .Fade

  weak var tableView: UITableView?

  var rowCountChangedHandler: (() -> ())?

  /**
  Initialize a delegate
  - parameter tableView: The table view to perform the changed the NSFetchedResultsController reports on
  */
  init(tableView: UITableView) {
    self.tableView = tableView
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView?.beginUpdates()
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      tableView?.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: sectionAnimation)

    case .Delete:
      tableView?.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: sectionAnimation)

    default:
      break // Noop
    }
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      //TODO: If-check moet niet. Bug in NSFetchedResultsControllerDelegate volgens http://stackoverflow.com/a/32336934/2092602
      if indexPath != newIndexPath {
        tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
      }
    case .Delete:
      tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)

    case .Move:
      tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
      tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)

    case .Update:
      tableView?.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
    }
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controllerDidChangeContent(controller: NSFetchedResultsController) {

    if let tableView = self.tableView {

      if tableView.numberOfSections > 0 {
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
      }

      if let rowCountChangedHandler = rowCountChangedHandler {
        rowCountChangedHandler()
      }

      tableView.endUpdates()
    }
  }
}