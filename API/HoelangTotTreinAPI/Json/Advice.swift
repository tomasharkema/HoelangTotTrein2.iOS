//
//  Advice.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import SWXMLHash

public struct FareTime: Equatable, Codable {
  public let planned: Date
  public let actual: Date
  public let delay: TimeInterval?
  
  init(planned: Date, actual: Date) {
    self.planned = planned
    self.actual = actual
    let interval = actual.timeIntervalSince(planned)
    self.delay = interval == 0 ? nil : interval
  }
}

struct FareTimeJson: Equatable, Codable {
  public let planned: Double
  public let actual: Double
}

public struct Melding: Equatable, Codable {
  let id: String
  let ernstig: Bool
  let text: String
}

public struct Stop: Equatable, Codable {
  public let time: Date
  public let spoor: String?
  public let name: String
}

public struct ReisDeel: Codable, Equatable {
  public let vervoerder: String
  public let vervoerType: String
  public let ritNummer: String?
  public let stops: [Stop]
}

public enum FareStatus: String, Codable {
  case volgensPlan = "VOLGENS-PLAN"
  case gewijzigd = "GEWIJZIGD"
  case nieuw = "NIEUW"
  case nietOptimaal = "NIET-OPTIMAAL"
  case nietMogelijk = "NIET-MOGELIJK"
  case geannuleerd = "GEANNULEERD"
  case overstapNietMogelijk = "OVERSTAP-NIET-MOGELIJK"
  case vertraagd = "VERTRAAGD"
  case planGewijzigd = "PLAN-GEWIJZGD"
    
  public static let impossibleFares: [FareStatus] = [
    .nietMogelijk,
    .geannuleerd
  ]
}

public struct AdviceRequestCodes: Codable, Equatable {
  public let from: String
  public let to: String
}

public struct AdviceIdentifier: RawRepresentable, Equatable, Codable {
  public let rawValue: String
  
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct Advice: Equatable, Codable {
  public let overstappen: Int
  public let vertrek: FareTime
  public let aankomst: FareTime
  public let melding: Melding?
  public let reisDeel: [ReisDeel]
  public let vertrekVertraging: String?
  public let status: FareStatus
  public let request: AdviceRequestCodes
  
  public var identifier: AdviceIdentifier {
    return AdviceIdentifier(rawValue: "\(vertrek.planned.timeIntervalSince1970):\(aankomst.planned.timeIntervalSince1970):\(request.from):\(request.to)")
  }
}

struct AdviceJson: Equatable, Codable {
  public let overstappen: Int
  public let vertrek: FareTimeJson
  public let aankomst: FareTimeJson
  public let melding: Melding?
  public let reisDeel: [ReisDeel]
  public let vertrekVertraging: String?
  public let status: FareStatus
  public let request: AdviceRequestCodes

  public func identifier() -> String {
    return "\(vertrek.planned):\(aankomst.planned):\(request.from):\(request.to)"
  }
}

public typealias Advices = [Advice]
typealias AdvicesJson = [AdviceJson]

struct AdvicesResultJson: Codable {
  public let advices: AdvicesJson

  public init(advices: AdvicesJson) {
    self.advices = advices
  }
}

public struct AdvicesResult {
  public let advices: Advices
  
  public init(advices: Advices) {
    self.advices = advices
  }
}

public struct AdviceRequest: Equatable, Codable {
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

public struct AdvicesAndRequest: Codable {
  public let advices: Advices
  public let adviceRequest: AdviceRequest
  public let lastUpdated: Date

  public init(advices: Advices, adviceRequest: AdviceRequest) {
    self.advices = advices
    self.adviceRequest = adviceRequest
    lastUpdated = Date()
  }
}

extension Advice {
  public init?(fromXml xml: XMLIndexer, request: AdviceRequestCodes) {
    guard let overstappenText = xml["AantalOverstappen"].element?.text,
      let overstappen = Int(overstappenText)
      else {
        return nil
      }

    self.overstappen = overstappen

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    guard let vertrek = xml["GeplandeVertrekTijd"].element?.text,
      let aankomst = xml["GeplandeAankomstTijd"].element?.text,
      let actueelVertrek = xml["ActueleVertrekTijd"].element?.text,
      let actueelAankomst = xml["ActueleAankomstTijd"].element?.text,

      let vertrekDate = dateFormatter.date(from: vertrek),
      let aankomstDate = dateFormatter.date(from: aankomst),
      let actueelVertrekDate = dateFormatter.date(from: actueelVertrek),
      let actueelAankomstDate = dateFormatter.date(from: actueelAankomst)
      else {
        return nil
      }

    self.vertrek = FareTime(planned: vertrekDate,
                            actual: actueelVertrekDate)
    self.aankomst = FareTime(planned: aankomstDate,
                             actual: actueelAankomstDate)

    self.melding = (xml["Melding"].element?.text).map {
      Melding(id: "", ernstig: false, text: $0)
    }

    self.reisDeel = xml["ReisDeel"].all.compactMap { deel in
      ReisDeel(fromXml: deel)
    }
    self.vertrekVertraging = nil

    guard let statusText = xml["Status"].element?.text,
      let status = FareStatus(rawValue: statusText) else {
      return nil
    }

    self.status = status

    self.request = request
  }
}

extension ReisDeel {
  init?(fromXml xml: XMLIndexer) {
    guard let vervoerder = xml["Vervoerder"].element?.text else {
      return nil
    }

    self.vervoerder = vervoerder

    guard let vervoerType = xml["VervoerType"].element?.text else {
      return nil
    }

    self.vervoerType = vervoerType

    self.ritNummer = xml["RitNummer"].element?.text
    
    self.stops = xml["ReisStop"].all.compactMap {
      Stop(fromXml: $0)
    }
  }
}

extension Stop {
  init?(fromXml xml: XMLIndexer) {
    guard let name = xml["Naam"].element?.text else {
      return nil
    }

    self.name = name

    spoor = xml["Spoor"].element?.text

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    guard let timeText = xml["Tijd"].element?.text,
      let time = dateFormatter.date(from: timeText)
      else {
        return nil
      }

    self.time = time
  }
}
