//
//  Advice+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

enum ModalityType {
  case Sprinter
  case Intercity
  case Other(String)

  static func fromString(name: String) -> ModalityType {
    if name == "Sprinter" {
      return .Sprinter
    }

    if name == "Intercity" {
      return .Intercity
    }

    return .Other(name)
  }

}

extension Advice {
  var vertrekSpoor: String? {
    return reisDeel.first?.stops.first?.spoor
  }

  var isOngoing: Bool {
    return (status == .VolgensPlan ||
      status == .Gewijzigd ||
      status == .Vertraagd ||
      status == .Nieuw) && vertrek.actualDate.timeIntervalSinceDate(NSDate()) > 0
  }
}

extension Advice: Hashable {
  var hashValue: Int {
    return "\(vertrek.planned):\(aankomst.planned):\(request.from):\(request.to)".hashValue
  }
}

extension ReisDeel {
  var modalityType: ModalityType {
    return ModalityType.fromString(vervoerType)
  }
}

extension Array: Equatable {}

public func ==<T: CollectionType>(lhs: T, rhs: T) -> Bool {
  return String(lhs) == String(rhs)
}

typealias Stations = [Station]

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
    return NSDate(timeIntervalSince1970: time/1000)
  }
}

extension StationType {
  var score: Int8 {
    switch self {
    case .MegaStation:
      return 4
    case .KnooppuntIntercityStation, .KnooppuntSneltreinStation:
      return 3
    case .IntercityStation, .SneltreinStation:
      return 2
    case .KnooppuntStoptreinStation:
      return 1
    case .StoptreinStation, .FacultatiefStation:
      return 0
    }
  }
}

extension FareStatus {
  var alertDescription: String {
    switch self {
    case .Vertraagd:
      return "vertraagd"
    case .NietOptimaal:
      return "niet optimaal"
    case .VolgensPlan:
      return "op tijd"
    default:
      return "whaa moeilijk"
    }
  }
}
