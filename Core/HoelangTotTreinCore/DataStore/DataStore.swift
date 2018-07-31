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
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

public enum DataStoreError: Error {
  case notFound
}

public protocol DataStore: class {
  func stations() -> Promise<[Station], Error>
  func findOrUpdate(stations: [Station]) -> Promise<Void, Error>
  func find(stationName: String) -> Promise<Station, Error>
  func find(stationCode: String) -> Promise<Station, Error>
  func find(inBounds bounds: Bounds) -> Promise<[Station], Error>
  func find(stationNameContains query: String) -> Promise<[Station], Error>
  func insertHistory(station: Station, historyType: HistoryType) -> Promise<Void, Error>
  func mostUsedStations() -> Promise<[Station], Error>
}
