//
//  PickerViewController.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import RxSwift
import HoelangTotTreinAPI
import HoelangTotTreinCore

extension PickerState: CustomStringConvertible {
  public var description: String {
    switch self {
    case .from:
      return R.string.localization.from()
    case .to:
      return R.string.localization.to()
    }
  }
}

class PickerViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

  var state: PickerState!
  var selectedStation: Station?

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var currentStation: UILabel!
  @IBOutlet weak var searchField: UITextField!

  var cancelHandler: (() -> ())?
  var successHandler: ((Station) -> ())?

  private var closeStations: [Station]?
  private var mostUsedStations: [Station]?
  private var ordinaryStations: [Station]?
  private var searchResults: [Station]?

  private let disposeBag = DisposeBag()

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

    searchField.attributedPlaceholder = NSAttributedString(string: R.string.localization.search(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.4)])

    App.travelService.getCloseStations()
      .dispatchMain()
      .then { [weak self] stations in
        assert(Thread.isMainThread)
        self?.closeStations = Array(stations.prefix(5))
        self?.tableView.reloadData()
      }

    App.travelService.stationsObservable
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] stations in
        assert(Thread.isMainThread)
        self?.ordinaryStations = stations
        self?.tableView.reloadData()
      })
      .disposed(by: disposeBag)

    App.travelService.mostUsedStationsObservable
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] stations in
        assert(Thread.isMainThread)
        self?.mostUsedStations = Array(stations.prefix(5))
        self?.tableView.reloadData()
      })
      .disposed(by: disposeBag)
  }

  func search(_ string: String) {
    App.travelService.find(stationNameContains: string)
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
    case (_, 0):
      return mostUsedStations?.count ?? 0
    case (_, 1):
      return closeStations?.count ?? 1
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
    case (_, 0):
      return mostUsedStations?[safe: indexPath.item]
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
    } else if indexPath.section == 1 {
      cell.stationLabel.text = R.string.localization.fetchingCloseStations()
    } else {
      cell.stationLabel.text = ""
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
      return R.string.localization.searchResults()
    }

    if section == 0 {
      return R.string.localization.recentlyUsed()
    } else if section == 1 {
      return R.string.localization.nearby()
    } else {
      return R.string.localization.stations()
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
