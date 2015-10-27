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
  let sectionOffset: Int
  var rowCountChangedHandler: (() -> ())?

  /**
  Initialize a delegate
  - parameter tableView: The table view to perform the changed the NSFetchedResultsController reports on
  */
  init(tableView: UITableView, sectionOffset: Int = 0) {
    self.tableView = tableView
    self.sectionOffset = sectionOffset
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView?.beginUpdates()
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      tableView?.insertSections(NSIndexSet(index: sectionIndex + sectionOffset), withRowAnimation: sectionAnimation)

    case .Delete:
      tableView?.deleteSections(NSIndexSet(index: sectionIndex + sectionOffset), withRowAnimation: sectionAnimation)

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
        tableView?.insertRowsAtIndexPaths([newIndexPath!.section(sectionOffset)], withRowAnimation: rowAnimation)
      }
    case .Delete:
      tableView?.deleteRowsAtIndexPaths([indexPath!.section(sectionOffset)], withRowAnimation: rowAnimation)

    case .Move:
      tableView?.deleteRowsAtIndexPaths([indexPath!.section(sectionOffset)], withRowAnimation: rowAnimation)
      tableView?.insertRowsAtIndexPaths([newIndexPath!.section(sectionOffset)], withRowAnimation: rowAnimation)

    case .Update:
      tableView?.reloadRowsAtIndexPaths([indexPath!.section(sectionOffset)], withRowAnimation: rowAnimation)
    }
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controllerDidChangeContent(controller: NSFetchedResultsController) {

    if let tableView = self.tableView {

      if tableView.numberOfSections > 0 {
        tableView.reloadSections(NSIndexSet(index: sectionOffset), withRowAnimation: .Automatic)
      }

      if let rowCountChangedHandler = rowCountChangedHandler {
        rowCountChangedHandler()
      }

      tableView.endUpdates()
    }
  }
}