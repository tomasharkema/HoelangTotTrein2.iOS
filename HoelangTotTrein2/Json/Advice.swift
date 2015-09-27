//
//  File.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct FareTime {
  let planned: Double
  let actual: Double
}

struct Melding {
  let id: String
  let ernstig: Bool
  let text: String
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

struct Advice {
  let overstappen: Int
  let vertrek: FareTime
  let melding: Melding?
  let reisDeel: [ReisDeel]
  let vertrekVertraging: String?
  //let status: FareStatus
  let status: String
}

struct AdvicesResult {
  let advices: [Advice]
}