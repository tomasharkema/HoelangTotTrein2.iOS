//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import HoelangTotTreinAPI

struct App {
  static private let dataStore = DataStore()
  static let apiService = ApiService()
  static let locationService = LocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)
  static let geofenceService = GeofenceService(travelService: travelService, dataStore: dataStore)
  static let notificationService = NotificationService(geofenceService: geofenceService)
  static let appShortcutService = AppShortcutService(travelService: travelService)
}

