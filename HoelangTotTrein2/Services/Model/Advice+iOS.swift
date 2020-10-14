//
//  Advice+iOS.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import API
import Core
import CoreData
import Foundation

extension Advice {
  var stepModels: [StepViewModel] {
    legs.compactMap { item in

      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm"

      return StepViewModel(
        fromStation: item.origin.name,
        toStation: item.destination.name,
        fromSpoor: item.origin.plannedTrack ?? "",
        toSpoor: item.destination.plannedTrack ?? "",
        fromTime: formatter.string(from: item.origin.time.actual),
        toTime: formatter.string(from: item.destination.time.actual),
        direction: item.direction,
        product: item.product.shortCategoryName
      )
    }
  }
}
