//
//  CLCircularRegion+Bounds.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreLocation
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

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
    return CLLocation(latitude: lat, longitude: lon)
  }
}

