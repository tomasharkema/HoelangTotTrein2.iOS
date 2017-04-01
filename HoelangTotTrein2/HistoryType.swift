//
//  HistoryType.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 01-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

enum HistoryType: Int {
  case from = 0
  case to = 1
}

extension History {
  var historyType: HistoryType! {
    get {
      return HistoryType(rawValue: type!.intValue)
    }
    set {
      type = newValue!.rawValue as NSNumber
    }
  }
}
