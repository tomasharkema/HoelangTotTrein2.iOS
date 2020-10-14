//
//  UIColor+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIColor {
  convenience init(hex: Int) {
    self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
              green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
              blue: CGFloat(hex & 0xFF) / 255.0,
              alpha: 1)
  }

  static func redTintColor() -> UIColor {
    UIColor(hex: 0xEC9393)
  }
}
