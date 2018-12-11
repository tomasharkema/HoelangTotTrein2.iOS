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

  private let session = WCSession.default

  var cachedAdvices: [Advice] = App.preferenceStore.persistedAdvicesAndRequest?.advices ?? []

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activate()
  }

  func applicationDidBecomeActive() {
    requestInitialState()
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
    if let data = userInfo["data"] as? Data {
      on(data: data)
    }
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    on(data: messageData)
  }
  
  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
    on(data: messageData)
    replyHandler(Data(bytes: []))
  }
  
  fileprivate func on(data: Data) {
    do {
      on(travelEvent: try JSONDecoder().decode(TravelEvent.self, from: data))
    } catch {
      print(error)
    }
  }

  fileprivate func on(travelEvent event: TravelEvent) {
    switch event {
    case let .advicesChange(advice: advices):
      cachedAdvices = advices
//      App.preferenceStore.persistedAdvicesAndRequest?.advices = advices

    case .currentAdviceChange(let data):
      let from = App.travelService.setStation(.from, stationCode: data.fromCode)
      let to = App.travelService.setStation(.to, stationCode: data.toCode)
      App.travelService.setCurrentAdviceOnScreen(adviceIdentifier: data.identifier)
      whenBoth(from, to).finallyResult {
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
      guard let service = self else {
        return
      }

      service.on(data: messageData)
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
    if let data = applicationContext["data"] as? Data {
      on(data: data)
    }
  }
}
