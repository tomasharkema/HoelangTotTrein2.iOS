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

let AdvicesDidChangeNotification = "AdvicesDidChangeNotification"

func getCurrentAdvice() -> Advice? {
  let currentHash = (WKExtension.sharedExtension().delegate as? ExtensionDelegate)?.cachedAdviceHash ?? UserDefaults.currentAdviceHash
  let advices = (WKExtension.sharedExtension().delegate as? ExtensionDelegate)?.cachedAdvices ?? UserDefaults.persistedAdvices

  let adviceOpt = advices?.filter {
    $0.hashValue == currentHash && $0.isOngoing
  }.first ?? advices?.filter {
    $0.isOngoing
  }.first

  return adviceOpt
}

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

  let session = WCSession.defaultSession()

  var cachedAdvices: [Advice] = UserDefaults.persistedAdvices ?? []
  var cachedAdviceHash: Int? = UserDefaults.currentAdviceHash

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activateSession()
  }

  func applicationDidBecomeActive() {
    requestInitialState()
  }

  func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
    requestInitialState()
  }

  func session(session: WCSession, didReceiveMessageData messageData: NSData) {
    guard let json = nsdataToJSON(messageData) as? [String : AnyObject] else {
      return
    }

    decodeEvent(json)
  }

  private func decodeEvent(message: [String: AnyObject]) {
    guard let event = TravelEvent.decode(message) else {
      return
    }

    switch event {
    case let .AdvicesChange(advice: advices):
      cachedAdvices = advices
      UserDefaults.persistedAdvices = advices

    case let .CurrentAdviceChange(currentHash):
      cachedAdviceHash = currentHash
      UserDefaults.currentAdviceHash = currentHash

    }

    NSNotificationCenter.defaultCenter().postNotificationName(AdvicesDidChangeNotification, object: nil)
    CLKComplicationServer.sharedInstance().activeComplications?.forEach {
      CLKComplicationServer.sharedInstance().reloadTimelineForComplication($0)
    }
  }

  func requestInitialState(completionHandler: ((NSError?) -> ())? = nil) {

    guard let someData = NSData(base64EncodedString: "initialstate", options: []) else {
      return
    }

    if session.activationState != .Activated {
      session.activateSession()
    }

    try? session.updateApplicationContext(["boot!": "Boot!"])

    session.sendMessageData(someData, replyHandler: { [weak self] messageData in
      guard let service = self, json = nsdataToJSON(messageData) as? [String : AnyObject] else {
        return
      }

      service.decodeEvent(json)
      completionHandler?(nil)
    }) { error in
      print(error)
      completionHandler?(error)
    }
  }

  func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
    requestInitialState()
  }
}
