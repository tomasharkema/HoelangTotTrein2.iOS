//
//  Advice+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

public enum ModalityType {
  case sprinter
  case intercity
  case intercityDirect
  case other(String)

  static func fromString(_ name: String) -> ModalityType {
    if name == "Sprinter" {
      return .sprinter
    }

    if name == "Intercity" {
      return .intercity
    }

    if name == "Intercity direct" {
      return .intercityDirect
    }

    return .other(name)
  }

  public var abbriviation: String {
    switch self {
    case .sprinter:
      return "SPR"
    case .intercity:
      return "IC"
    case .intercityDirect:
      return "ICD"
    case .other(let string):
      return string
    }
  }

}

extension Advice {
  public var vertrekSpoor: String? {
    return legs.first?.origin.plannedTrack
  }

  public var aankomstSpoor: String? {
    return legs.last?.destination.plannedTrack
  }

  
  public var departure: FareTime {
    return legs.first!.origin.time
  }
  
  public var arrival: FareTime {
    return legs.last!.destination.time
  }
  
  public var isOngoing: Bool {
//    let isPossible = FareStatus.impossibleFares.first { $0 == status } == nil
    
//    return isPossible &&
    return departure.actual > Date()
      && arrival.actual > Date()
  }
  
  public var startStation: String? {
    return legs.first?.origin.name
  }
  
  public var endStation: String? {
    return legs.last?.destination.name
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
//extension ReisDeel {
//  public var modalityType: ModalityType {
//    return ModalityType.fromString(vervoerType)
//  }
//}
