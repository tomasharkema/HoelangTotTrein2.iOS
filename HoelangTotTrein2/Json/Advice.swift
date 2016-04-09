//
//  Advice.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct FareTime: Equatable {
  let planned: Double
  let actual: Double
}

func ==(lhs: FareTime, rhs: FareTime) -> Bool {
  return lhs.planned == rhs.planned && lhs.actual == rhs.actual
}

struct Melding: Equatable {
  let id: String
  let ernstig: Bool
  let text: String
}

func ==(lhs: Melding, rhs: Melding) -> Bool {
  return lhs.id == rhs.id && lhs.ernstig == rhs.ernstig && lhs.text == rhs.text
}

struct Stop: Equatable {
  let time: Double
  let spoor: String?
  let name: String
}

func ==(lhs: Stop, rhs: Stop) -> Bool {
  return lhs.time == rhs.time &&
    lhs.spoor == rhs.spoor &&
    lhs.name == rhs.name
}

struct ReisDeel {
  let vervoerder: String
  let vervoerType: String
  let stops: [Stop]
}

enum FareStatus: String {
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

struct AdviceRequestCodes {
  let from: String
  let to: String
}

struct Advice: Equatable {
  let overstappen: Int
  let vertrek: FareTime
  let aankomst: FareTime
  let melding: Melding?
  let reisDeel: [ReisDeel]
  let vertrekVertraging: String?
  let status: FareStatus
  let request: AdviceRequestCodes
}

typealias Advices = [Advice]

func ==(lhs: Advice, rhs: Advice) -> Bool {
  return lhs.overstappen == rhs.overstappen &&
    lhs.vertrek == rhs.vertrek &&
    lhs.melding == rhs.melding &&
    lhs.vertrekVertraging == rhs.vertrekVertraging &&
    lhs.status == rhs.status
}

struct AdvicesResult {
  let advices: Advices
}

struct AdviceRequest: Equatable {
  let from: Station?
  let to: Station?

  func setFrom(from: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }

  func setTo(to: Station) -> AdviceRequest {
    return AdviceRequest(from: from, to: to)
  }
}

func ==(lhs: AdviceRequest, rhs: AdviceRequest) -> Bool {
  return lhs.from == rhs.from && lhs.to == rhs.to
}

struct AdvicesAndRequest {
  let advices: Advices
  let adviceRequest: AdviceRequest
}
