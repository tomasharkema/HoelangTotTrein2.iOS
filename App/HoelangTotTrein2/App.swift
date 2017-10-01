//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import HoelangTotTreinAPI
import HoelangTotTreinCore

struct App {
  static private let dataStore = AppDataStore(defaultKeepDepartedAdvice: true)
  static private let apiService = HttpXmlApiService(credentials: Credentials(file: Bundle.main.url(forResource: "xml-credentials", withExtension: "plist")!))
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)
  static let transferService = TransferService(travelService: travelService, dataStore: dataStore)
  static let notificationService = NotificationService(transferService: transferService, dataStore: dataStore, apiService: apiService)
  static let appShortcutService = AppShortcutService(travelService: travelService)
}

