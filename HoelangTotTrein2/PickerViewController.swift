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

extension PickerState: CustomStringConvertible {
  var description: String {
    switch self {
    case .From:
      return "From"
    case .To:
      return "To"
    }
  }
}


class PickerViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

  var state: PickerState!
  var selectedStation: Station?

  @IBOutlet weak var tableView: PickerTableView!
  @IBOutlet weak var currentStation: UILabel!
  @IBOutlet weak var searchField: UITextField!

  var cancelHandler: (() -> ())?
  var successHandler: ((Station) -> ())?

  var historyStationsFetchedResultsController: NSFetchedResultsController?
  var closeFetchedResultController: NSFetchedResultsController?
  var ordinaryStationsFetchedResultsController: NSFetchedResultsController?

  var isSearching: Bool {
    return searchField.text ?? "" != ""
  }

  var fetchedResultControllers: [NSFetchedResultsController?] {

    return
      (isSearching ? [] :
        [historyStationsFetchedResultsController,
        closeFetchedResultController]
        ) +
      [ordinaryStationsFetchedResultsController]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    currentStation.text = state.description

    App.travelService.getCloseStations().then { stations in
      do {
        if let closeStationsFetchRequest = fetchedRequest(stations) {
          self.closeFetchedResultController = try CDK.mainThreadContext.fetchedResultsController(closeStationsFetchRequest)
          self.tableView.reloadData()
        }
      } catch {
        print(error)
      }
    }

    do {
      let ordinaryStationsFetchRequest = try CDK.mainThreadContext.createFetchRequest(StationRecord.self, predicate: nil, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
      let ordinaryStationsFetchedResultsControllerDelegate = StationFetchedResultControllerDelegate(tableView: tableView)
      ordinaryStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(ordinaryStationsFetchRequest, delegate: ordinaryStationsFetchedResultsControllerDelegate)

      let historyUsedFetchRequest = try CDK.mainThreadContext.createFetchRequest(History.self, predicate: nil, sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
      historyUsedFetchRequest.propertiesToGroupBy = ["station"]
      historyUsedFetchRequest.resultType = .DictionaryResultType
      historyUsedFetchRequest.propertiesToFetch = ["station"]

      historyStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(historyUsedFetchRequest)

      tableView.reloadData()
    } catch {
      print(error)
    }
  }

  func search(string: String) {
    let predicate: NSPredicate? = string == "" ? nil : NSPredicate(format: "name CONTAINS[cd] %@", string)
    do {
      let ordinaryStationsFetchRequest = try CDK.mainThreadContext.createFetchRequest(StationRecord.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
      let ordinaryStationsFetchedResultsControllerDelegate = StationFetchedResultControllerDelegate(tableView: tableView)
      ordinaryStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(ordinaryStationsFetchRequest, delegate: ordinaryStationsFetchedResultsControllerDelegate)
      tableView.reloadData()
    } catch {
      print(error)
    }
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultControllers.count ?? 0
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if fetchedResultControllers.count > section && fetchedResultControllers.count != 0 {
      return fetchedResultControllers[section]?.sections?[0].numberOfObjects ?? 0
    } else {
      return 0
    }
  }

  func getStation(fromIndexPath indexPath: NSIndexPath) -> StationRecord? {
    let obj = fetchedResultControllers[indexPath.section]?.optionalObjectAtIndexPath(indexPath.section(-indexPath.section))

    if let station = obj as? StationRecord {
      return station
    } else if let stationHistory = obj as? [String: AnyObject], stationID = stationHistory["station"] as? NSManagedObjectID, station = (try? CDK.mainThreadContext.find(StationRecord.self, managedObjectID: stationID)) {
      return station
    }

    return nil
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.stationCell, forIndexPath: indexPath)! as StationCell

    if let station = getStation(fromIndexPath: indexPath) {
      cell.stationLabel.text = station.name
    }

    return cell
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let station = getStation(fromIndexPath: indexPath) {
      successHandler?(station.toStation())
    }
  }

  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

    if isSearching {
      return "Search results"
    }

    if section == 0 {
      return "Recently Used"
    } else if section == 1 {
      return "Nearby"
    } else {
      return "Stations"
    }
  }

  @IBAction func closedPressed(sender: AnyObject) {
    cancelHandler?()
  }

  @IBAction func texstfieldTouchDown(sender: AnyObject) {
    search(searchField.text ?? "")
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }
}