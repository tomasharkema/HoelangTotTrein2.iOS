//
//  WatchkitHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import WatchConnectivity

struct WatchkitHelpers {
  static func sendCurrentAdvice(session: WCSession, from: String, to: String) {
    if session.reachable {
      session.sendMessage(["message": "adviceChange", "adviceFrom": from, "adviceTo": to], replyHandler: nil, errorHandler: nil)
    } else {
      do {
        try session.updateApplicationContext(["message": "adviceChange", "adviceFrom": from, "adviceTo": to])
      } catch {
        print(error)
      }
    }
  }
}