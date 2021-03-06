//
//  Advice.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

public struct FareTime: Equatable, Codable, Hashable {
  public let planned: Date
  public let actual: Date
  public let delay: TimeInterval?

  init(planned: Date, actual: Date) {
    self.planned = planned
    self.actual = actual
    let interval = actual.timeIntervalSince(planned)
    delay = interval == 0 ? nil : interval
  }
}

struct FareTimeJson: Equatable, Codable {
  public let planned: Double
  public let actual: Double
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

public struct LegPlace: Equatable, Codable, Hashable {
  public let type: String
  public let prognosisType: String
  public let plannedTimeZoneOffset: Int
  public let plannedDateTime: Date
  public let actualTimeZoneOffset: Int?
  public let actualDateTime: Date?
  public let plannedTrack: String?
  public let actualTrack: String?
  public let checkinStatus: String
  public let name: String
  public let lng: Double
  public let lat: Double
  public let countryCode: String
  public let uicCode: UicCode
  public let weight: Int?
  public let products: Int?
  public let exitSide: String?

  public var time: FareTime {
    FareTime(planned: plannedDateTime, actual: actualDateTime ?? plannedDateTime)
  }
}

public struct Product: Equatable, Codable, Hashable {
  public let number: String
  public let categoryCode: String
  public let shortCategoryName: String
  public let longCategoryName: String
  public let operatorCode: String
  public let operatorName: String
  public let type: String
  public let displayName: String?
}

public protocol LegStation {
  var name: String { get }
  var lng: Double { get }
  var lat: Double { get }
  var countryCode: String { get }
  var uicCode: UicCode { get }
}

public struct PassingStation: LegStation, Equatable, Codable, Hashable {
  public let name: String
  public let lng: Double
  public let lat: Double
  public let countryCode: String
  public let uicCode: UicCode
  public let passing: Bool
}

public struct HaltStation: LegStation, Equatable, Codable, Hashable {
  public let name: String
  public let lng: Double
  public let lat: Double
  public let city: String?
  public let countryCode: String
  public let uicCode: UicCode
  public let weight: Int?
  public let products: Int?
  public let routeIdx: Int
  public let plannedDepartureDateTime: Date? // arrival leg?
  public let plannedDepartureTimeZoneOffset: Int? // arrival leg?
  public let actualDepartureDateTime: Date?
  public let actualDepartureTimeZoneOffset: Int?
  public let plannedDepartureTrack: String? // arrival leg?
  public let actualDepartureTrack: String?
  public let plannedArrivalDateTime: Date?
  public let plannedArrivalTimeZoneOffset: Int?
  public let actualArrivalDateTime: Date?
  public let actualArrivalTimeZoneOffset: Int?
  public let plannedArrivalTrack: String?
  public let actualArrivalTrack: String?
  public let departureDelayInSeconds: Int?
  public let arrivalDelayInSeconds: Int?
  public let cancelled: Bool
  public let quayCode: String?
}

public enum Stop: Equatable, Codable, LegStation, Hashable {
  case stop(HaltStation)
  case passing(PassingStation)

  public init(from decoder: Decoder) throws {
    do {
      self = .passing(try PassingStation(from: decoder))
    } catch { do {
      self = .stop(try HaltStation(from: decoder))
    } catch {
      throw error
    } }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .passing(let passing):
      try passing.encode(to: encoder)
    case .stop(let stop):
      try stop.encode(to: encoder)
    }
  }

  private var legStation: LegStation {
    switch self {
    case .passing(let passing):
      return passing
    case .stop(let stop):
      return stop
    }
  }

  public var halt: HaltStation? {
    switch self {
    case .stop(let stop):
      return stop
    case .passing:
      return nil
    }
  }

  public var name: String {
    legStation.name
  }

  public var lng: Double {
    legStation.lng
  }

  public var lat: Double {
    legStation.lat
  }

  public var countryCode: String {
    legStation.countryCode
  }

  public var uicCode: UicCode {
    legStation.uicCode
  }

  public var time: Date? {
    switch self {
    case .stop(let stop):
      return stop.actualDepartureDateTime
    case .passing:
      return nil
    }
  }
}

public enum CrowdForecast: String, Codable {
  case high = "HIGH"
  case medium = "MEDIUM"
  case low = "LOW"
  case unknown = "UNKNOWN"
}

public struct Leg: Equatable, Codable, Hashable {
  public let idx: String
  public let name: String
  public let travelType: String
  public let direction: String?
  public let cancelled: Bool
  public let changePossible: Bool
  public let alternativeTransport: Bool
  public let journeyDetailRef: String?
  public let product: Product

  public let origin: LegPlace
  public let destination: LegPlace
  public let stops: [Stop]
  public let steps: [String] // TODO:
  public let crowdForecast: CrowdForecast?
  public let punctuality: Double?
  public let reachable: Bool
}

public enum FareStatus: String, Codable, Hashable {
  case CANCELLED
  case CHANGE_NOT_POSSIBLE
  case CHANGE_COULD_BE_POSSIBLE
  case ALTERNATIVE_TRANSPORT
  case DISRUPTION
  case MAINTENANCE
  case REPLACEMENT
  case ADDITIONAL
  case SPECIAL
  case NORMAL
}

public struct Advice: Equatable, Codable, Hashable {
  public let plannedDurationInMinutes: Int
  public let transfers: Int
  public let status: FareStatus
  public let legs: [Leg]
  public let overviewPolyLine: [String] // TODO:
  public let checksum: String
  public let crowdForecast: CrowdForecast?
  public let punctuality: Double?
  public let ctxRecon: String
  public let actualDurationInMinutes: Int
  public let idx: Int
  public let optimal: Bool
  public let type: String
  public let realtime: Bool

  public var identifier: AdviceIdentifier {
    AdviceIdentifier(rawValue: checksum)
  }
}

public typealias Advices = [Advice]

public struct AdviceRequest: Equatable, Codable {
  public var from: UicCode?
  public var to: UicCode?

  public init(from: UicCode?, to: UicCode?) {
    self.from = from
    self.to = to
  }
}

public struct AdviceStations {
  public let from: String?
  public let to: String?

  public init(from: String?, to: String?) {
    self.from = from
    self.to = to
  }
}

extension AdviceStations: Equatable, Codable {}

public struct AdvicesAndRequest: Codable {
  public let advices: Advices
  public let adviceRequest: AdviceRequest
  public let lastUpdated: Date

  public init(advices: Advices, adviceRequest: AdviceRequest, lastUpdated: Date = Date()) {
    self.advices = advices
    self.adviceRequest = adviceRequest
    self.lastUpdated = lastUpdated
  }
}

public struct AdvicesResponse: Codable {
  public let trips: Advices
  public let scrollRequestBackwardContext: String
  public let scrollRequestForwardContext: String
  public let message: String?
}
