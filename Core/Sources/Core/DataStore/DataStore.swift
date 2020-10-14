//
//  DataStore.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import Bindable
import API

public enum DataStoreError: Error {
  case notFound
}

public protocol DataStore: class {
  func stations() -> Promise<[Station], Error>
  func findOrUpdate(stations: [Station]) -> Promise<Void, Error>
  func find(stationName: String) -> Promise<Station, Error>
  func find(stationCode: StationCode) -> Promise<Station, Error>
  func find(uicCode: UicCode) -> Promise<Station, Error>
  func find(inBounds bounds: Bounds) -> Promise<[Station], Error>
  func find(stationNameContains query: String) -> Promise<[Station], Error>
  func insertHistory(stationCode: UicCode, historyType: HistoryType) -> Promise<Void, Error>
  func mostUsedStations() -> Promise<[Station], Error>
}
