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
    return reisDeel.first?.stops.first?.spoor
  }

  public var aankomstSpoor: String? {
    return reisDeel.last?.stops.last?.spoor
  }

  public var isOngoing: Bool {
    let isPossible = FareStatus.impossibleFares.first { $0 == status } == nil
    
    return isPossible
      && vertrek.actual > Date()
      && aankomst.actual > Date()
  }

  public var startStation: String? {
    return self.reisDeel.first?.stops.first?.name
  }

  public var endStation: String? {
    return self.reisDeel.last?.stops.last?.name
  }
}

extension ReisDeel {
  public var modalityType: ModalityType {
    return ModalityType.fromString(vervoerType)
  }
}

extension Stop {
  public var timeDate: Date {
    return Date(timeIntervalSince1970: time/1000)
  }
}
