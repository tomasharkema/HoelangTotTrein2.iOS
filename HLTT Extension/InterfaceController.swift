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

  @IBOutlet var fromButton: WKInterfaceButton!
  @IBOutlet var toButton: WKInterfaceButton!
  @IBOutlet var timerLabel: WKInterfaceTimer!

  override init() {
    session = WCSession.defaultSession()
    super.init()
    session.delegate = self
  }

  func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
    decodeEvent(message)
  }

  func session(session: WCSession, didReceiveMessageData messageData: NSData) {
    guard let json = nsdataToJSON(messageData) as? [String : AnyObject] else {
      return
    }

    decodeEvent(json)
  }

  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
    session.activateSession()
    session.sendMessageData(NSData(base64EncodedString: "initialstate", options: [])!, replyHandler: { [weak self] messageData in
      guard let service = self, json = nsdataToJSON(messageData) as? [String : AnyObject] else {
        return
      }

      service.decodeEvent(json)
    }) { error in
      print(error)
    }
    print(context)
  }

  override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
  }

  override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
  }

  private func decodeEvent(message: [String: AnyObject]) {
    guard let event = TravelEvent.decode(message) else {
      return
    }
    handleEvent(event)
  }

  private func handleEvent(event: TravelEvent) {
    switch event {
    case let .AdviceChange(advice):
      fromButton.setTitle(advice.startStation)
      toButton.setTitle(advice.endStation)
      timerLabel.setDate(advice.vertrek.actualDate)
      timerLabel.start()
    }

    print(event)
  }

}
