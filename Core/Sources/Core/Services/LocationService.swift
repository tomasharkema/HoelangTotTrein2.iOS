//
//  LocationService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import CoreLocation

public protocol LocationService {
  func currentLocation() -> Promise<CLLocation, Error>
}
