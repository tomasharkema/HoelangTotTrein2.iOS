
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity
import Promissum

#if os(watchOS)
  import HoelangTotTreinAPIWatch
  import HoelangTotTreinCoreWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
  import HoelangTotTreinCore
#endif


extension WCSession {
  func sendEvent(_ event: TravelEvent) {
    if activationState != .activated {
      activate()
    }
    do {
      let data = try JSONEncoder().encode(event)
      if self.isReachable {
        sendMessageData(data, replyHandler: nil, errorHandler: nil)
      } else {
        try updateApplicationContext(["data": data])
      }
    } catch {
      print(error)
    }
  }
}
