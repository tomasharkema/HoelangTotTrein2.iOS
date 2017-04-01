
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity

enum TravelEvent {
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
  var encode: [String: Any] {
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
  static func decode(_ message: [String: AnyObject]) -> TravelEvent? {
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

extension WCSession {
  func sendEvent(_ event: TravelEvent) {
    do {
      if let data = jsonToNSData(event.encode), self.isReachable {
        self.sendMessageData(data, replyHandler: nil, errorHandler: { error in
          print(error)
        })
      } else {
        //try self.updateApplicationContext(event.encode)
      }
    } catch {
      assertionFailure("Some failiure: \(error)")
    }
  }
}
