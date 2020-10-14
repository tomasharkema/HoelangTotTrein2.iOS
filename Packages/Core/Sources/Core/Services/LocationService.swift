//
//  LocationService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import CoreLocation
import Foundation
import Promissum

public protocol LocationService {
  func currentLocation() -> Promise<CLLocation, Error>
}
