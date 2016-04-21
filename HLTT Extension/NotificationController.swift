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


  override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {
    if let userInfo = localNotification.userInfo, _ = try? GeofenceModel.decodeJson(userInfo) {
      completionHandler(.Custom)
    } else {
      completionHandler(.Default)
    }
  }


  override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: ((WKUserNotificationInterfaceType) -> Void)) {

    if let userInfo = remoteNotification["geofenceModel"] as? [String: AnyObject], model = try? GeofenceModel.decodeJson(userInfo) {
      guard let platform = model.fromStop?.spoor, date = model.fromStop?.timeDate else {
        completionHandler(.Default)
        return
      }
      platformLabel.setText("platform \(platform)")
      timeLabel.setDate(date)
      timeLabel.start()
      completionHandler(.Custom)
    } else {
      completionHandler(.Default)
    }

  }

}
