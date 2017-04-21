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
    return reisDeel.last?.stops.first?.spoor
  }

  public var isOngoing: Bool {
    return (status == .VolgensPlan
      || status == .Gewijzigd
      || status == .Vertraagd
      || status == .Nieuw)
      && vertrek.actualDate > Date()
      && aankomst.actualDate > Date()
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

extension FareTime {
  public var plannedDate: Date {
    return Date(timeIntervalSince1970: planned/1000)
  }

  public var actualDate: Date {
    return Date(timeIntervalSince1970: actual/1000)
  }
}

extension Stop {
  public var timeDate: Date {
    return Date(timeIntervalSince1970: time/1000)
  }
}
