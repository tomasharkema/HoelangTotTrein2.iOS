//
//  TravelEvent.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

public enum TravelEvent {
  case advicesChange(advice: Advices)
  case currentAdviceChange(hash: Int)
}

extension TravelEvent {
  var name: String {
    switch self {
    case .advicesChange:
      return "advicesChange"
    case .currentAdviceChange:
      return "currentAdviceChange"
    }
  }
}

//MARK: - TravelEvent Encode
extension TravelEvent {
  public var encode: [String: Any] {
    let array: [String: Any] = { this in
      switch this {
      case let .advicesChange(advices):
        return ["advices": advices.encodeJson {
          $0.encodeJson()
          }]

      case let .currentAdviceChange(hash):
        return ["hash": hash]
      }
    }(self)

    var arrayAndMessage = array
    arrayAndMessage["name"] = self.name
    return arrayAndMessage
  }
}

//MARK: - TravelEvent Decode

extension TravelEvent {
  public static func decode(_ message: [String: AnyObject]) -> TravelEvent? {
    switch message["name"] as? String {
    case "advicesChange"?:
      guard let advices = message["advices"] as? [AnyObject] else {
        return nil
      }
      do {
        return TravelEvent.advicesChange(advice: try Array.decodeJson({ try Advice.decodeJson($0) })(advices))
      } catch {
        return nil
      }

    case "currentAdviceChange"?:
      guard let hash = message["hash"] as? Int else {
        return nil
      }
      return TravelEvent.currentAdviceChange(hash: hash)

    default:
      return nil
    }
  }
}
