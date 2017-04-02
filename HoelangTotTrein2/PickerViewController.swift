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

  private var closeStations: [Station]?
  private var ordinaryStations: [Station]?
  private var searchResults: [Station]?

  var isSearching: Bool {
    return searchField.text ?? "" != ""
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    tableView.backgroundView = UIView()
    tableView.backgroundColor = UIColor.clear

    currentStation.text = state.description

    searchField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.4)])

    App.travelService.getCloseStations().then { [weak self] stations in
      self?.closeStations = stations
      self?.tableView.reloadData()
    }

    App.dataStore.stations()
      .then { [weak self] stations in
        self?.ordinaryStations = stations
        self?.tableView.reloadData()
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
    App.dataStore.find(stationNameContains: string)
      .then { [weak self] stations in
        self?.searchResults = stations
        self?.tableView.reloadData()
      }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return isSearching ? 1 : 3
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (isSearching, section) {
    case (true, _):
      return searchResults?.count ?? 0
    case (_, 1):
      return closeStations?.count ?? 0
    case (_, 2):
      return ordinaryStations?.count ?? 0
    default:
      return 0
    }
  }

  func getStation(fromIndexPath indexPath: IndexPath) -> Station? {
    switch (isSearching, indexPath.section) {
    case (true, _):
      return searchResults?[safe: indexPath.item]
    case (_, 1):
      return closeStations?[safe: indexPath.item]
    case (_, 2):
      return ordinaryStations?[safe: indexPath.item]
    default:
      return nil
    }
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
      successHandler?(station)
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
