//
//  Advice+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension FareTime {
  var plannedDate: NSDate {
    return NSDate(timeIntervalSince1970: planned/1000)
  }

  var actualDate: NSDate {
    return NSDate(timeIntervalSince1970: actual/1000)
  }
}

extension Stop {
  var timeDate: NSDate {
    return NSDate(timeIntervalSince1970: time)
  }
}