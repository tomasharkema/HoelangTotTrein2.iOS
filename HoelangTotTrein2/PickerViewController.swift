//
//  PickerViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
//import CoreDataKit

enum PickerState {
  case from
  case to
}

extension PickerState: CustomStringConvertible {
  var description: String {
    switch self {
    case .from:
      return "From"
    case .to:
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

//  var historyStationsFetchedResultsController: NSFetchedResultsController?
//  var closeFetchedResultController: NSFetchedResultsController?
//  var ordinaryStationsFetchedResultsController: NSFetchedResultsController?

  var isSearching: Bool {
    return searchField.text ?? "" != ""
  }

//  var fetchedResultControllers: [NSFetchedResultsController?] {
//
//    return
//      (isSearching ? [] :
//        [historyStationsFetchedResultsController,
//        closeFetchedResultController]
//        ) +
//      [ordinaryStationsFetchedResultsController]
//  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    tableView.backgroundView = UIView()
    tableView.backgroundColor = UIColor.clear

    currentStation.text = state.description

    searchField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.4)])

    App.travelService.getCloseStations().then { stations in
//      do {
//        if let closeStationsFetchRequest = fetchedRequest(stations) {
//          self.closeFetchedResultController = try CDK.mainThreadContext.fetchedResultsController(closeStationsFetchRequest)
//          self.tableView.reloadData()
//        }
//      } catch {
//        print(error)
//      }
    }

//    do {
//      let ordinaryStationsFetchRequest = try CDK.mainThreadContext.createFetchRequest(StationRecord.self, predicate: nil, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
//      let ordinaryStationsFetchedResultsControllerDelegate = StationFetchedResultControllerDelegate(tableView: tableView)
//      ordinaryStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(ordinaryStationsFetchRequest, delegate: ordinaryStationsFetchedResultsControllerDelegate)
//
//      let historyUsedFetchRequest = try CDK.mainThreadContext.createFetchRequest(History.self, predicate: nil, sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
//      historyUsedFetchRequest.propertiesToGroupBy = ["station"]
//      historyUsedFetchRequest.resultType = .DictionaryResultType
//      historyUsedFetchRequest.propertiesToFetch = ["station"]
//
//      historyStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(historyUsedFetchRequest)
//
//      tableView.reloadData()
//    } catch {
//      print(error)
//    }
  }

  func search(_ string: String) {
//    let predicate: NSPredicate? = string == "" ? nil : NSPredicate(format: "name CONTAINS[cd] %@", string)
//    do {
//      let ordinaryStationsFetchRequest = try CDK.mainThreadContext.createFetchRequest(StationRecord.self, predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
//      let ordinaryStationsFetchedResultsControllerDelegate = StationFetchedResultControllerDelegate(tableView: tableView)
//      ordinaryStationsFetchedResultsController = try CDK.mainThreadContext.fetchedResultsController(ordinaryStationsFetchRequest, delegate: ordinaryStationsFetchedResultsControllerDelegate)
//      tableView.reloadData()
//    } catch {
//      print(error)
//    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 0//fetchedResultControllers.count ?? 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if false {//fetchedResultControllers.count > section { //&& fetchedResultControllers.count != 0 {
      return 0 //fetchedResultControllers[section]?.sections?[0].numberOfObjects ?? 0
    } else {
      return 0
    }
  }

  func getStation(fromIndexPath indexPath: IndexPath) -> StationRecord? {
//    let obj = fetchedResultControllers[indexPath.section]?.optionalObjectAtIndexPath(indexPath.section(-indexPath.section))
//
//    if let station = obj as? StationRecord {
//      return station
//    } else if let stationHistory = obj as? [String: AnyObject], let stationID = stationHistory["station"] as? NSManagedObjectID, let station = (try? CDK.mainThreadContext.find(StationRecord.self, managedObjectID: stationID)) {
//      return station
//    }

    return nil
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.stationCell, for: indexPath)! as StationCell

    if let station = getStation(fromIndexPath: indexPath) {
      cell.stationLabel.text = station.name
    }

    cell.backgroundColor = .clear
    cell.backgroundView = UIView()

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let station = getStation(fromIndexPath: indexPath) {
      searchField.resignFirstResponder()
//      successHandler?(station.toStation())
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

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

  @IBAction func closedPressed(_ sender: AnyObject) {
    cancelHandler?()
  }

  @IBAction func texstfieldTouchDown(_ sender: AnyObject) {
    search(searchField.text ?? "")
  }

  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return .portrait
  }

  override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }
}
