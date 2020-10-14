
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import API
import Foundation
import Promissum
import WatchConnectivity

extension WCSession {
  func sendEvent(_ event: TravelEvent) {
    if activationState != .activated {
      activate()
    }
    do {
      let data = try JSONEncoder().encode(event)
      if isReachable {
        sendMessageData(data, replyHandler: nil, errorHandler: nil)
      } else {
        try updateApplicationContext(["data": data])
      }
    } catch {
      print(error)
    }
  }
}
