//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import HoelangTotTreinAPI
import HoelangTotTreinCore

struct App {
  static private let dataStore = AppDataStore()
  static private let apiService = HttpApiService(endpoint: "https://ns.harkema.io")
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)
//  static let geofenceService = GeofenceService(travelService: travelService, dataStore: dataStore)
//  static let notificationService = NotificationService(geofenceService: geofenceService, dataStore: dataStore, apiService: apiService)
//  static let appShortcutService = AppShortcutService(travelService: travelService)
}
