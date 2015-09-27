//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit

struct Keys {
  static let FromStationCodeKey = "FromStationCodeKey"
  static let ToStationCodeKey = "ToStationCodeKey"
}

let UserDefaults = NSUserDefaults.standardUserDefaults()

extension NSUserDefaults {
  var fromStationCode: String? {
    get {
      let fromCode = stringForKey(Keys.FromStationCodeKey)
      return fromCode
    }
    set {
      setObject(newValue, forKey: Keys.FromStationCodeKey)
    }
  }

  var toStationCode: String? {
    get {
      let toCode = stringForKey(Keys.ToStationCodeKey)
      return toCode
    }
    set {
      setObject(newValue, forKey: Keys.ToStationCodeKey)
    }
  }
}
