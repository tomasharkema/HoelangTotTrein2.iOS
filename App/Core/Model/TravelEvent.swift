//
//  TravelEvent.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
#if canImport(API)
import API
#endif

public struct CurrentAdviceChangeData: Codable {
  public let identifier: AdviceIdentifier
  public let fromCode: UicCode
  public let toCode: UicCode
}

public enum TravelEvent {
  case advicesChange(advice: Advices)
  case currentAdviceChange(change: CurrentAdviceChangeData)
  
  enum CodingKeys: String, CodingKey {
    case advicesChange = "advicesChange"
    case currentAdviceChange = "currentAdviceChange"
    case name = "_name"
  }
}

extension TravelEvent: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .advicesChange(let advices):
      try container.encode("advicesChange", forKey: .name)
      try container.encode(advices, forKey: .advicesChange)
    case .currentAdviceChange(let change):
      try container.encode("currentAdviceChange", forKey: .name)
      try container.encode(change, forKey: .currentAdviceChange)
    }
  }
}

extension TravelEvent: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    guard container.contains(.name) else {
      throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "Expect name")
    }
    
    let name = try container.decode(String.self, forKey: .name)
    
    switch name {
    case "advicesChange":
      self = .advicesChange(advice: try container.decode(Advices.self, forKey: .advicesChange))
    case "currentAdviceChange":
      self = .currentAdviceChange(change: try container.decode(CurrentAdviceChangeData.self, forKey: .currentAdviceChange))
    default:
      throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "Expect name to be advicesChange or currentAdviceChange")
    }
  }
}
