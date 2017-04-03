//
//  Station+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 02-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

extension Coords {
  var location: CLLocation {
    return CLLocation(latitude: lat, longitude: lon)
  }
}
