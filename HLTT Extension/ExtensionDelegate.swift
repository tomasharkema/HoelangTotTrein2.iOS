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

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

  let session = WCSession.defaultSession()

  var cachedAdvices: [Advice] = UserDefaults.persistedAdvices ?? []
  var cachedAdviceHash: Int? = UserDefaults.currentAdviceHash

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activateSession()

    session.activateSession()

    print(session.outstandingUserInfoTransfers)
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

  func requestInitialState() {

    guard let someData = NSData(base64EncodedString: "initialstate", options: []) else {
      return
    }

    session.sendMessageData(someData, replyHandler: { [weak self] messageData in
      guard let service = self, json = nsdataToJSON(messageData) as? [String : AnyObject] else {
        return
      }

      service.decodeEvent(json)
    }) { error in
      print(error)
    }
  }
}
