//
//  NotificationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift

class NotificationService {
  let geofenceService: GeofenceService
  private let disposeBag = DisposeBag()

  init(geofenceService: GeofenceService) {
    self.geofenceService = geofenceService
  }

  private func fireNotification(title: String, body: String, userInfo: [String: AnyObject]?) {
    let notification = UILocalNotification()
    notification.alertTitle = title
    notification.alertBody = body

    notification.soundName = UILocalNotificationDefaultSoundName
    notification.alertAction = "Show"

    notification.userInfo = userInfo
    notification.category = userInfo == nil ? nil : "nextStationNotification"

    UIApplication.sharedApplication().presentLocalNotificationNow(notification)
  }

  private func secondsToStringOffset(jsTime jsTime: Double) -> String {
    let offset = NSDate(timeIntervalSince1970: jsTime / 1000).timeIntervalSinceDate(NSDate())
    let difference = NSDate(timeIntervalSince1970: offset - 60*60)
    return difference.toString(format: .Custom("mm:ss"))
  }
  //TODO: FIX OLD AND NEW GEOFENCE MODEL!!
  private func notifyForGeofenceModel(oldModel: GeofenceModel, _ updatedModel: GeofenceModel? = nil) {
    assert(NSThread.isMainThread())

    let correctModel = updatedModel ?? oldModel

    switch oldModel.type {
    case .Start:
      let timeString = secondsToStringOffset(jsTime: oldModel.fromStop?.time ?? 0)
      fireNotification("Arrived at Start Station", body: "You've arrived. Your train leaves in \(timeString) min on platform \(oldModel.fromStop?.spoor ?? "")", userInfo: oldModel.encodeJson())

    case .TussenStation:
      let timeDiff = oldModel.fromStop?.timeDate.timeIntervalSinceDate(NSDate()) ?? 0
      let timeString = NSDate(timeIntervalSince1970: timeDiff).toString(format: .Custom("mm:ss"))
      let timeMessage = timeDiff > 0 ? "laat" : "vroeg"
//      fireNotification("Tussen Station", body: "Je bent nu op \(oldModel.fromStop?.name ?? ""), \(timeString) te \(timeMessage)", userInfo: oldModel.encodeJson())

    case .Overstap:
      let timeString = secondsToStringOffset(jsTime: correctModel.fromStop?.time ?? 0)
      fireNotification("Change Platform", body: "Change to platform \(correctModel.fromStop?.spoor ?? ""). \(timeString) min to go", userInfo: ["geofenceModel": oldModel.encodeJson()])

    case .End:
      fireNotification("Final stop", body: "Get off the train here. Please remember to check out.", userInfo: nil)
    }
  }

  func attach() {
    geofenceService.geofenceObservable
      .observeOn(MainScheduler.asyncInstance)
      .subscribeNext { [weak self] geofenceModel in
        self?.notifyForGeofenceModel(geofenceModel)
      }.addDisposableTo(disposeBag)
  }
}
