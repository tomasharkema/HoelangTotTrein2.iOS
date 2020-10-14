//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import API
import Core
import Foundation
import SwiftUI

struct App {
  private static let dataStore = AppDataStore(defaultKeepDepartedAdvice: true)
  private static let preferenceStore = UserDefaultsPreferenceStore(defaultKeepDepartedAdvice: true)
  private static let apiService = HttpApiService(credentials: ApiCredentials(file: Bundle.main.url(forResource: "json-credentials", withExtension: "plist")!))
  static let heartBeat = HeartBeat()
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore, preferenceStore: preferenceStore, heartBeat: heartBeat)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore, preferenceStore: preferenceStore)
  static let transferService = TransferService(travelService: travelService, dataStore: dataStore, preferenceStore: preferenceStore)
  static let notificationService = NotificationService(transferService: transferService, dataStore: dataStore, preferenceStore: preferenceStore, apiService: apiService)
  static let appShortcutService = AppShortcutService(travelService: travelService)
}
