//
//  PickerViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import CoreDataKit

enum PickerState {
  case From
  case To
}

class PickerViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

  var state: PickerState!
  var selectedStation: Station!

  var fetchedResultsController: NSFetchedResultsController?
  var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

  @IBOutlet weak var tableView: PickerTableView!

  var cancelHandler: (() -> ())?
  var successHandler: ((Station) -> ())?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    do {
      let frq = try CDK.mainThreadContext.createFetchRequest(StationRecord.self, predicate: nil, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])

      fetchedResultsControllerDelegate = StationFetchedResultControllerDelegate(tableView: tableView)
      fetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(frq, delegate: fetchedResultsControllerDelegate)

      tableView.reloadData()
    } catch {
      print(error)
    }
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultsController?.sections?.count ?? 0
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.stationCell, forIndexPath: indexPath)! as StationCell
    if let station = fetchedResultsController?.optionalObjectAtIndexPath(indexPath) as? StationRecord {
      cell.stationLabel.text = station.name
    }
    return cell
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let station = fetchedResultsController?.optionalObjectAtIndexPath(indexPath) as? StationRecord {
      successHandler?(station.toStation())
    }
  }

}