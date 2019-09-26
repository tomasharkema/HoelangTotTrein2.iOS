//
//  Bounds.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

public struct Bounds {
  public let latmin: Double
  public let latmax: Double

  public let lonmin: Double
  public let lonmax: Double

  public init(latmin: Double, latmax: Double, lonmin: Double, lonmax: Double) {
    self.latmax = latmax
    self.latmin = latmin
    self.lonmin = lonmin
    self.lonmax = lonmax
  }
}
