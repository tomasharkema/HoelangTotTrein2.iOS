//
//  InterfaceController.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

  let session: WCSession

  override init() {
    session = WCSession.defaultSession()
    super.init()
    session.delegate = self
  }

  func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
    print(message)

    switch message["type"] as? String {
    case "adviceChange"?:
      print(message["from"])

    default:
      assertionFailure("Unhandled message")
    }

  }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        session.activateSession()
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
