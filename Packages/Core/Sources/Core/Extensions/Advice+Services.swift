//
//  Advice+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import API
import Foundation

extension Advice {
  public var vertrekSpoor: String? {
    legs.first?.origin.plannedTrack
  }

  public var aankomstSpoor: String? {
    legs.last?.destination.plannedTrack
  }

  public var departure: FareTime {
    legs.first!.origin.time
  }

  public var arrival: FareTime {
    legs.last!.destination.time
  }

  public var time: TimeInterval {
    arrival.actual.timeIntervalSince(departure.actual)
  }

  public var isOngoing: Bool {
//    let isPossible = FareStatus.impossibleFares.first { $0 == status } == nil

//    return isPossible &&
    status != .CANCELLED && departure.actual > Date()
      && arrival.actual > Date()
  }

  public var startStation: LegPlace? {
    legs.first?.origin
  }

  public var endStation: LegPlace? {
    legs.last?.destination
  }

  public var vertrekVertraging: String? {
    let timeInterval = departure.actual.timeIntervalSince(departure.planned)
    if timeInterval == 0 {
      return nil
    }
    return "\(departure.actual.timeIntervalSince(departure.planned))"
  }
}

//
// extension ReisDeel {
//  public var modalityType: ModalityType {
//    return ModalityType.fromString(vervoerType)
//  }
// }
