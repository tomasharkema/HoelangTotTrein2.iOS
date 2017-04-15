//
//  Advice.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

public struct FareTime: Equatable {
  public let planned: Double
  public let actual: Double
}

public func ==(lhs: FareTime, rhs: FareTime) -> Bool {
  return lhs.planned == rhs.planned && lhs.actual == rhs.actual
}

public struct Melding: Equatable {
  let id: String
  let ernstig: Bool
  let text: String
}

public func ==(lhs: Melding, rhs: Melding) -> Bool {
  return lhs.id == rhs.id && lhs.ernstig == rhs.ernstig && lhs.text == rhs.text
}

public struct Stop: Equatable {
  public let time: Double
  public let spoor: String?
  public let name: String
}

public func ==(lhs: Stop, rhs: Stop) -> Bool {
  return lhs.time == rhs.time &&
    lhs.spoor == rhs.spoor &&
    lhs.name == rhs.name
}

public struct ReisDeel {
  public let vervoerder: String
  public let vervoerType: String
  public let stops: [Stop]
}

public enum FareStatus: String {
  case VolgensPlan = "VOLGENS-PLAN"
  case Gewijzigd = "GEWIJZIGD"
  case Nieuw = "NIEUW"
  case NietOptimaal = "NIET-OPTIMAAL"
  case NietMogelijk = "NIET-MOGELIJK"
  case Geannuleerd = "GEANNULEERD"
  case OverstapNietMogelijk = "OVERSTAP-NIET-MOGELIJK"
  case Vertraagd = "VERTRAAGD"
  case PlanGewijzigd = "PLAN-GEWIJZGD"
}

public struct AdviceRequestCodes {
  public let from: String
  public let to: String
}

public struct Advice: Equatable {
  public let overstappen: Int
  public let vertrek: FareTime
  public let aankomst: FareTime
  public let melding: Melding?
  public let reisDeel: [ReisDeel]
  public let vertrekVertraging: String?
  public let status: FareStatus
  public let request: AdviceRequestCodes
}

public typealias Advices = [Advice]

public func ==(lhs: Advice, rhs: Advice) -> Bool {
  return lhs.overstappen == rhs.overstappen &&
    lhs.vertrek == rhs.vertrek &&
    lhs.melding == rhs.melding &&
    lhs.vertrekVertraging == rhs.vertrekVertraging &&
    lhs.status == rhs.status
}

public struct AdvicesResult {
  public let advices: Advices
}

public struct AdviceRequest: Equatable {
  public var from: Station?
  public var to: Station?

  public init(from: Station?, to: Station?) {
    self.from = from
    self.to = to
  }
  
  public func setFrom(_ from: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }

  public func setTo(_ to: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }
}

public func ==(lhs: AdviceRequest, rhs: AdviceRequest) -> Bool {
  return lhs.from == rhs.from && lhs.to == rhs.to
}

public struct AdvicesAndRequest {
  public let advices: Advices
  public let adviceRequest: AdviceRequest

  public init(advices: Advices, adviceRequest: AdviceRequest) {
    self.advices = advices
    self.adviceRequest = adviceRequest
  }
}
