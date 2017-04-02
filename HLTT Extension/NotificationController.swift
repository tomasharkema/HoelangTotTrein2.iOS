//
//  NotificationController.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import WatchKit
import Foundation

class NotificationController: WKUserNotificationInterfaceController {

  @IBOutlet var platformLabel: WKInterfaceLabel!
  @IBOutlet var timeLabel: WKInterfaceTimer!

  override init() {
      // Initialize variables here.
      super.init()
      
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


  override func didReceive(_ localNotification: UILocalNotification, withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {
    if let userInfo = localNotification.userInfo, let _ = try? GeofenceModel.decodeJson(userInfo) {
      completionHandler(.custom)
    } else {
      completionHandler(.default)
    }
  }


  override func didReceiveRemoteNotification(_ remoteNotification: [AnyHashable: Any], withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {

    if let userInfo = remoteNotification["geofenceModel"] as? [String: AnyObject], let model = try? GeofenceModel.decodeJson(userInfo) {
      guard let platform = model.fromStop?.spoor, let date = model.fromStop?.timeDate else {
        completionHandler(.default)
        return
      }
      platformLabel.setText("platform \(platform)")
      timeLabel.setDate(date)
      timeLabel.start()
      completionHandler(.custom)
    } else {
      completionHandler(.default)
    }

  }

}
