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

class InterfaceController: WKInterfaceController {

  @IBOutlet var platformLabel: WKInterfaceLabel!
  @IBOutlet var fromButton: WKInterfaceButton!
  @IBOutlet var toButton: WKInterfaceButton!
  @IBOutlet var timerLabel: WKInterfaceTimer!
  @IBOutlet var tickerContainer: WKInterfaceGroup!
  @IBOutlet var loadingLabel: WKInterfaceLabel!
  @IBOutlet var delayLabel: WKInterfaceLabel!

  var refreshTimer: NSTimer?

  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)

    loadingLabel.setHidden(false)
    tickerContainer.setHidden(true)
    print(context)
    adviceDidChange()
  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(adviceDidChange), name: AdvicesDidChangeNotification, object: nil)
    (WKExtension.sharedExtension().delegate as? ExtensionDelegate)?.requestInitialState()
    super.willActivate()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }

  func adviceDidChange() {
    let currentHash = (WKExtension.sharedExtension().delegate as? ExtensionDelegate)?.cachedAdviceHash ?? UserDefaults.currentAdviceHash
    let advices = (WKExtension.sharedExtension().delegate as? ExtensionDelegate)?.cachedAdvices ?? UserDefaults.persistedAdvices

    let adviceOpt = advices?.filter {
      $0.hashValue == currentHash && $0.isOngoing
    }.first ?? advices?.filter {
      $0.isOngoing
    }.first

    guard let advice = adviceOpt else {
      return
    }

    fromButton.setTitle(advice.startStation)
    toButton.setTitle(advice.endStation)
    timerLabel.setDate(advice.vertrek.actualDate)
    timerLabel.start()

    platformLabel.setText(advice.vertrekSpoor)
    delayLabel.setText(advice.vertrekVertraging)

    loadingLabel.setHidden(true)
    tickerContainer.setHidden(false)

    refreshTimer?.invalidate()
    let finished = advice.vertrek.actualDate.timeIntervalSinceNow
    refreshTimer = NSTimer.scheduledTimerWithTimeInterval(finished, target: self, selector: #selector(adviceDidChange), userInfo: nil, repeats: false)
  }

  func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
    print(userInfo)
  }
  
}
