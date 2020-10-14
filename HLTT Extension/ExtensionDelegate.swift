//
//  ExtensionDelegate.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import API
import ClockKit
import Core
import Promissum
import WatchConnectivity
import WatchKit

let AdvicesDidChangeNotification = "AdvicesDidChangeNotification"

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
  private let session = WCSession.default

  var cachedAdvices: [Advice] = App.preferenceStore.persistedAdvicesAndRequest(for: App.preferenceStore.adviceRequest.value)?.advices ?? []

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activate()
  }

  func applicationDidBecomeActive() {
    requestInitialState()
  }

  func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    if let data = userInfo["data"] as? Data {
      on(data: data)
    }
  }

  func session(_: WCSession, didReceiveMessageData messageData: Data) {
    on(data: messageData)
  }

  func session(_: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
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
    case .advicesChange(advice: let advices):
      cachedAdvices = advices
//      App.preferenceStore.persistedAdvicesAndRequest?.advices = advices

    case .currentAdviceChange(let data):
      App.travelService.setStation(.from, byPicker: false, uicCode: data.fromCode)
      App.travelService.setStation(.to, byPicker: false, uicCode: data.toCode)
      App.travelService.setCurrentAdviceOnScreen(adviceIdentifier: data.identifier)
    }

    NotificationCenter.default.post(name: Notification.Name(rawValue: AdvicesDidChangeNotification), object: nil)
    CLKComplicationServer.sharedInstance().activeComplications?.forEach {
      CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
    }
  }

  func requestInitialState(_ completionHandler: ((Error?) -> Void)? = nil) {
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

  func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
    requestInitialState()
  }

  func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    if let data = applicationContext["data"] as? Data {
      on(data: data)
    }
  }
}
