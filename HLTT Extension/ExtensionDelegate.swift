//
//  ExtensionDelegate.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

  let session = WCSession.defaultSession()

  func applicationDidFinishLaunching() {
    session.delegate = self
    session.activateSession()
    sendCurrentState()
  }

  func applicationDidBecomeActive() {
    sendCurrentState()
  }

  private func sendCurrentState() {
    let advicesAndRequest = UserDefaults.persistedAdvicesAndRequest

    guard let advice = advicesAndRequest?.advices.first else {
      return 
    }
    session.sendEvent(.AdviceChange(advice: advice))
  }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

}
