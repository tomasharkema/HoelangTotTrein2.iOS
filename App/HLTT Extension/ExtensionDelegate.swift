//
//  ExtensionDelegate.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import WatchKit
import WatchConnectivity
import ClockKit
import HoelangTotTreinAPIWatch
import HoelangTotTreinCoreWatch
import Promissum

let AdvicesDidChangeNotification = "AdvicesDidChangeNotification"

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

  private let session = WCSession.default()

  var cachedAdvices: [Advice] = WatchApp.dataStore.persistedAdvices ?? []

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activate()
  }

  func applicationDidBecomeActive() {
    requestInitialState()
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
    requestInitialState()
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    guard let json = nsdataToJSON(messageData) as? [String : AnyObject] else {
      return
    }

    decodeEvent(json)
  }

  fileprivate func decodeEvent(_ message: [String: Any]) {
    guard let event = TravelEvent.decode(message) else {
      return
    }

    switch event {
//    case let .advicesChange(advice: advices):
//      cachedAdvices = advices
//      WatchApp.dataStore.persistedAdvices = advices

    case let .currentAdviceChange(currentHash, fromCode, toCode):
      let from = WatchApp.travelService.setStation(.from, stationCode: fromCode, byPicker: true)
      let to = WatchApp.travelService.setStation(.to, stationCode: toCode, byPicker: true)

      whenBoth(from, to).then {
        print($0)
      }.trap {
        print($0)
      }
    }

    NotificationCenter.default.post(name: Notification.Name(rawValue: AdvicesDidChangeNotification), object: nil)
    CLKComplicationServer.sharedInstance().activeComplications?.forEach {
      CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
    }
  }

  func requestInitialState(_ completionHandler: ((Error?) -> ())? = nil) {

    guard let someData = Data(base64Encoded: "initialstate", options: []) else {
      return
    }

    if session.activationState != .activated {
      session.activate()
    }

    try? session.updateApplicationContext(["boot!": "Boot!"])

    session.sendMessageData(someData, replyHandler: { [weak self] messageData in
      guard let service = self, let json = nsdataToJSON(messageData) as? [String : AnyObject] else {
        return
      }

      service.decodeEvent(json)
      completionHandler?(nil)
    }) { error in
      print(error)
      completionHandler?(error)
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    requestInitialState()
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    print(applicationContext)
    decodeEvent(applicationContext)
  }
}
