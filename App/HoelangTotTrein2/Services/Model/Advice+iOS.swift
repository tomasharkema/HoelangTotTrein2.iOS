//
//  Advice+iOS.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif

extension Advice {
  var stepModels: [StepViewModel] {
    return reisDeel.compactMap { item in
      if let from = item.stops.first, let to = item.stops.last {

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return StepViewModel(
          fromStation: from.name,
          toStation: to.name,
          fromSpoor: from.spoor ?? "",
          toSpoor: to.spoor ?? "",
          fromTime: formatter.string(from: from.time),
          toTime: formatter.string(from: to.time)
        )
      }
      return nil
    }
  }
  
}
