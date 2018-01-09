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

struct WidgetApp {
  static private let dataStore = AppDataStore(defaultKeepDepartedAdvice: false)
  static private let apiService = HttpXmlApiService(credentials: Credentials(file: Bundle.main.url(forResource: "xml-credentials", withExtension: "plist")!))
  static let locationService = AppLocationService()
  static let travelService = TravelService(apiService: apiService, locationService: locationService, dataStore: dataStore)
  static let storageAttachment = StorageAttachment(travelService: travelService, dataStore: dataStore)
}
