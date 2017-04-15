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
  var sectionAnimation: UITableViewRowAnimation = .fade
  var rowAnimation: UITableViewRowAnimation = .fade

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
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView?.beginUpdates()
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    switch type {
    case .insert:
      tableView?.insertSections(IndexSet(integer: sectionIndex + sectionOffset), with: sectionAnimation)

    case .delete:
      tableView?.deleteSections(IndexSet(integer: sectionIndex + sectionOffset), with: sectionAnimation)

    default:
      break // Noop
    }
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      //TODO: If-check moet niet. Bug in NSFetchedResultsControllerDelegate volgens http://stackoverflow.com/a/32336934/2092602
      if indexPath != newIndexPath {
        tableView?.insertRows(at: [newIndexPath!.section(sectionOffset)], with: rowAnimation)
      }
    case .delete:
      tableView?.deleteRows(at: [indexPath!.section(sectionOffset)], with: rowAnimation)

    case .move:
      tableView?.deleteRows(at: [indexPath!.section(sectionOffset)], with: rowAnimation)
      tableView?.insertRows(at: [newIndexPath!.section(sectionOffset)], with: rowAnimation)

    case .update:
      tableView?.reloadRows(at: [indexPath!.section(sectionOffset)], with: rowAnimation)
    }
  }

  /// Implementation of NSFetchedResultsControllerDelegate
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

    if let tableView = self.tableView {

      if tableView.numberOfSections > 0 {
        tableView.reloadSections(IndexSet(integer: sectionOffset), with: .automatic)
      }

      if let rowCountChangedHandler = rowCountChangedHandler {
        rowCountChangedHandler()
      }

      tableView.endUpdates()
    }
  }
}
