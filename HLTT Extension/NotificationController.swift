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
  

//  override func didReceive(_ localNotification: UILocalNotification,
//                           withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {
//
//    let decoder = JSONDecoder()
//    if let _ = localNotification.userInfo {
//      completionHandler(.custom)
//    } else {
//      completionHandler(.default)
//    }
//  }


//  override func didReceiveRemoteNotification(_ remoteNotification: [AnyHashable: Any],
//                                             withCompletion completionHandler: (@escaping (WKUserNotificationInterfaceType) -> Void)) {
//
//    let decoder = JSONDecoder()
//
//    guard let userInfo = remoteNotification["geofenceModel"],
//      let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []),
//      let model = try? decoder.decode(GeofenceModel.self, from: data),
//      let platform = model.stop.plannedTrack
//      else {
//        completionHandler(.default)
//        return
//      }
//
//    platformLabel.setText("platform \(platform)")
//    timeLabel.setDate(model.stop.time)
//    timeLabel.start()
//    completionHandler(.custom)
//  }

}
