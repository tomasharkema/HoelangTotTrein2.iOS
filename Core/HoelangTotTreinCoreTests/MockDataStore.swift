//
//  MockApiService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 15-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
@testable import HoelangTotTreinCore
@testable import HoelangTotTreinAPI
import Promissum

enum MockError: Error {
  case notImplemented
}

class MockDataStore: DataStore {

  private var _stations = [
    Station(name: "Zaandam", code: "ZD", land: "NL", coords: Coords(lat: 50, lon: 50), type: nil),
    Station(name: "Amsterdam Centraal", code: "AMS", land: "NL", coords: Coords(lat: 60, lon: 60), type: nil),
    Station(name: "Den Haag HS", code: "HS", land: "NL", coords: Coords(lat: 70, lon: 70), type: nil)
  ]

  private var _history = [(Station, HistoryType)]()

  func stations() -> Promise<[Station], Error> {
    return Promise(value: _stations)
  }

  func findOrUpdate(stations: [Station]) -> Promise<Void, Error> {
    _stations = stations
    return Promise(value: ())
  }

  func find(stationName name: String) -> Promise<Station, Error> {
    let found = _stations.first {
      $0.name == name
    }

    if let found = found {
      return Promise(value: found)
    } else {
      return Promise(error: DataStoreError.notFound)
    }
  }

  func find(stationCode code: String) -> Promise<Station, Error> {
    let found = _stations.first {
      $0.code == code
    }

    if let found = found {
      return Promise(value: found)
    } else {
      return Promise(error: DataStoreError.notFound)
    }
  }

  func find(inBounds bounds: Bounds) -> Promise<[Station], Error> {
    return Promise(value: _stations.filter {
      let coords = $0.coords
      return bounds.latmin <= coords.lat &&
        bounds.latmax >= coords.lat &&
        bounds.lonmin <= coords.lon &&
        bounds.lonmax >= coords.lon
    })
  }

  func find(stationNameContains query: String) -> Promise<[Station], Error> {
    let found = _stations.filter {
      $0.name.contains(query)
    }

    return Promise(value: found)
  }

  func insertHistory(station: Station, historyType: HistoryType) -> Promise<Void, Error> {
    _history.append((station, historyType))
    return Promise(value: ())
  }

  func mostUsedStations() -> Promise<[Station], Error> {
    return Promise(value: _history.map { $0.0 })
  }

  var fromStationCode: String? = nil
  var toStationCode: String? = nil
  var fromStationByPickerCode: String? = nil
  var toStationByPickerCode: String? = nil
  var userId: String = "AABBCC"
  var geofenceInfo: [String: [GeofenceModel]]? = nil
  var persistedAdvicesAndRequest: AdvicesAndRequest? = nil
  var currentAdviceHash: Int? = nil
  var persistedAdvices: Advices? = nil

}
