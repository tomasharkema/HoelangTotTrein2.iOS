//
//  CLCircularRegion+Bounds.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import API
import CoreLocation
import UIKit

extension CLCircularRegion {
  var bounds: Bounds {
    let latmin = center.latitude - radius
    let latmax = center.latitude + radius
    let lonmin = center.longitude - radius
    let lonmax = center.longitude + radius
    return Bounds(latmin: latmin, latmax: latmax, lonmin: lonmin, lonmax: lonmax)
  }
}

extension Coords {
  public var location: CLLocation {
    CLLocation(latitude: lat, longitude: lng)
  }
}
