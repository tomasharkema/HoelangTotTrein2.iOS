//
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity

enum TravelEvent {
  case AdviceChange(advice: Advice)
}

extension TravelEvent {
  var name: String {
    switch self {
    case .AdviceChange:
      return "adviceChange"
    }
  }
}

//MARK: - TravelEvent Encode
extension TravelEvent {
  var encode: [String: AnyObject] {
    let array: [String: AnyObject] = { this in
      switch this {
      case let .AdviceChange(advice):
        return advice.encodeJson()
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
    case "adviceChange"?:
      do {
        return TravelEvent.AdviceChange(advice: try Advice.decodeJson(message))
      } catch {
        print(error)
        return nil
      }

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
        try self.updateApplicationContext(event.encode)
      }
    } catch {
      assertionFailure("Some failiure: \(error)")
    }
  }
}