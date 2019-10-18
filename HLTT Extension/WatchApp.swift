//
//  WatchApp.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 21-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
#if canImport(API)
import API
#endif
#if canImport(Core)
import Core
#endif
#if canImport(APIWatch)
import APIWatch
#endif
#if canImport(CoreWatch)
import CoreWatch
#endif

struct App {
  private static let dataStore = AppDataStore(defaultKeepDepartedAdvice: false)
  static private let apiService = HttpApiService(credentials: ApiCredentials(file: Bundle.main.url(forResource: "json-credentials", withExtension: "plist")!))
  static let heartBeat = HeartBeat()
  static let locationService = AppLocationService()
  static let preferenceStore = UserDefaultsPreferenceStore(defaultKeepDepartedAdvice: false)
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore, preferenceStore: preferenceStore, heartBeat: heartBeat)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore, preferenceStore: preferenceStore)
}
