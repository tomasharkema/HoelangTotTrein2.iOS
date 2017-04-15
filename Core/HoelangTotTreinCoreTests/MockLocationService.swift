//
//  MockLocationService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 15-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
@testable import HoelangTotTreinCore
import Promissum
import CoreLocation

class MockLocationService: LocationService {
  func currentLocation() -> Promise<CLLocation, Error> {
    return Promise(value: CLLocation(latitude: 0, longitude: 0))
  }
}
