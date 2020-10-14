//
//  NotificationViewController.swift
//  TickerNotification
//
//  Created by Tomas Harkema on 09-06-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import API
import Core
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

  @IBOutlet weak var from: UILabel!
  @IBOutlet weak var to: UILabel!
  @IBOutlet weak var time: TimeLabel!

  override func viewDidLoad() {
      super.viewDidLoad()
      // Do any required interface initialization here.
  }
    
  func didReceive(_ notification: UNNotification) {

    print(notification.request)

    from.text = "\(notification.request.content.userInfo)"

    guard
      let geofenceModelJson = notification.request.content.userInfo["geofenceModel"],
      let geofenceModel = try? GeofenceModel.decodeJson(data: geofenceModelJson),
      case .stop(let stop) = geofenceModel.stop
      else {
        return
      }

    from.text = "\(geofenceModel.stop.name) \(stop.actualDepartureDateTime)" //"\(geofenceModel.fromStop?.name ?? "") (\(geofenceModel.fromStop?.timeDate.description ?? ""))"
    to.text = "" //"\(geofenceModel.toStop?.name ?? "") (\(geofenceModel.toStop?.timeDate.description ?? ""))"
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    time.formatter = formatter
    time.date = stop.actualDepartureDateTime
  }

}
