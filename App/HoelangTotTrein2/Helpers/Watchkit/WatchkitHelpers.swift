
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity
#if os(watchOS)
  import HoelangTotTreinAPIWatch
  import HoelangTotTreinCoreWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
  import HoelangTotTreinCore
#endif


extension WCSession {
  func sendEvent(_ event: TravelEvent) {
    do {
      if let data = jsonToNSData(event.encode), self.isReachable {
        self.sendMessageData(data, replyHandler: nil, errorHandler: { error in
          print(error)
        })
      } else {
        try self.updateApplicationContext(event.encode)
      }
    } catch {
//      assertionFailure("Some failiure: \(error)")
    }
  }
}
