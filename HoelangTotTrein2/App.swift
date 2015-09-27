//
//  App.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct App {
  static let apiService = ApiService()
  static let travelService = TravelService(apiService: apiService)
  static let storageAttachment = StorageAttachment(travelService: travelService)
}