//
//  Advice+Services.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

enum ModalityType {
  case sprinter
  case intercity
  case other(String)

  static func fromString(_ name: String) -> ModalityType {
    if name == "Sprinter" {
      return .sprinter
    }

    if name == "Intercity" {
      return .intercity
    }

    return .other(name)
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
      status == .Nieuw) && vertrek.actualDate.timeIntervalSince(Date()) > 0
  }

  var startStation: String? {
    return self.reisDeel.first?.stops.first?.name
  }

  var endStation: String? {
    return self.reisDeel.last?.stops.last?.name
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

public func ==<T: Collection>(lhs: T, rhs: T) -> Bool {
  return String(describing: lhs) == String(describing: rhs)
}

typealias Stations = [Station]

extension FareTime {
  var plannedDate: Date {
    return Date(timeIntervalSince1970: planned/1000)
  }

  var actualDate: Date {
    return Date(timeIntervalSince1970: actual/1000)
  }
}

extension Stop {
  var timeDate: Date {
    return Date(timeIntervalSince1970: time/1000)
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
      return "delayed"
    case .NietOptimaal:
      return "not optimal"
    case .VolgensPlan:
      return "on time"
    default:
      return "somethings wrong"
    }
  }
}
