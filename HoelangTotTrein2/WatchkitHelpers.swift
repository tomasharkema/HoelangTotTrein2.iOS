
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity

enum TravelEvent {
  case AdvicesChange(advice: Advices)
  case CurrentAdviceChange(hash: Int)
}

extension TravelEvent {
  var name: String {
    switch self {
    case .AdvicesChange:
      return "advicesChange"
    case .CurrentAdviceChange:
      return "currentAdviceChange"
    }
  }
}

//MARK: - TravelEvent Encode
extension TravelEvent {
  var encode: [String: AnyObject] {
    let array: [String: AnyObject] = { this in
      switch this {
      case let .AdvicesChange(advices):
        return ["advices": advices.encodeJson {
          $0.encodeJson()
        }]

      case let .CurrentAdviceChange(hash):
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
  static func decode(message: [String: AnyObject]) -> TravelEvent? {
    switch message["name"] as? String {
    case "advicesChange"?:
      guard let advices = message["advices"] as? [AnyObject] else {
        return nil
      }
      do {
        return TravelEvent.AdvicesChange(advice: try Array.decodeJson({ try Advice.decodeJson($0) }, advices))
      } catch {
        return nil
      }

    case "currentAdviceChange"?:
      guard let hash = message["hash"] as? Int else {
        return nil
      }
      return TravelEvent.CurrentAdviceChange(hash: hash)

    default:
      return nil
    }
  }
}

extension WCSession {
  func sendEvent(event: TravelEvent) {
    do {
      if let data = jsonToNSData(event.encode) where self.reachable {
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