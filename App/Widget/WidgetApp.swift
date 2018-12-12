//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif
import HoelangTotTreinCore

struct App {
  static let heartBeat = HeartBeat()
  static private let preferenceStore = UserDefaultsPreferenceStore(defaultKeepDepartedAdvice: false)
  static private let dataStore = AppDataStore(defaultKeepDepartedAdvice: false)
  static private let apiService = HttpApiService(credentials: ApiCredentials(file: Bundle.main.url(forResource: "json-credentials", withExtension: "plist")!))
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore, preferenceStore: preferenceStore, heartBeat: heartBeat)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore, preferenceStore: preferenceStore)
}
