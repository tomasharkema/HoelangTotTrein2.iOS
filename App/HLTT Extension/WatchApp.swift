//
//  WatchApp.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 21-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import HoelangTotTreinAPIWatch
import HoelangTotTreinCoreWatch

class WatchApp {
  //TODO: make private
  static let dataStore = AppDataStore(defaultKeepDepartedAdvice: false)
  static private let apiService = HttpXmlApiService(credentials: Credentials(file: Bundle.main.url(forResource: "xml-credentials", withExtension: "plist")!))
  static let heartBeat = HeartBeat()
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore, heartBeat: heartBeat)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)
}
