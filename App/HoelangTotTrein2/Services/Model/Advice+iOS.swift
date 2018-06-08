//
//  Advice+iOS.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import HoelangTotTreinAPI

extension Advice {
  var stepModels: [StepViewModel] {
    return reisDeel.flatMap { item in
      if let from = item.stops.first, let to = item.stops.last {
        return StepViewModel(
          fromStation: from.name,
          toStation: to.name,
          fromSpoor: from.spoor ?? "",
          toSpoor: to.spoor ?? "",
          fromTime: from.time.toString(format: .custom("HH:mm")),
          toTime: to.time.toString(format: .custom("HH:mm"))
        )
      }
      return nil
    }
  }
  
}
