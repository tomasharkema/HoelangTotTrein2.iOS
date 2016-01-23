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

struct Stop {
  let time: Double
  let spoor: String?
  let name: String
}

struct ReisDeel {
  let vervoerder: String
  let vervoerType: String
  let stops: [Stop]
}

enum FareStatus: String {
  case VolgensPlan = "VOLGENS-PLAN"
}

struct Advice: Equatable {
  let overstappen: Int
  let vertrek: FareTime
  let melding: Melding?
  let reisDeel: [ReisDeel]
  let vertrekVertraging: String?
  //let status: FareStatus
  let status: String
}

func ==(lhs: Advice, rhs: Advice) -> Bool {
  return lhs.overstappen == rhs.overstappen &&
    lhs.vertrek == rhs.vertrek &&
    lhs.melding == rhs.melding &&
    lhs.vertrekVertraging == rhs.vertrekVertraging &&
    lhs.status == rhs.status
}

struct AdvicesResult {
  let advices: [Advice]
}