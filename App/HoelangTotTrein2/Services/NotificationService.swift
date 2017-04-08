//
//  NotificationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift
import HoelangTotTreinAPI

class NotificationService {
  let geofenceService: GeofenceService
  fileprivate let disposeBag = DisposeBag()

  init(geofenceService: GeofenceService) {
    self.geofenceService = geofenceService
  }

  fileprivate func fireNotification(_ title: String, body: String, category: String?, userInfo: [String: Any]?) {
    let notification = UILocalNotification()
    notification.alertTitle = title
    notification.alertBody = body

    notification.soundName = UILocalNotificationDefaultSoundName
    notification.alertAction = "Show"

    notification.userInfo = userInfo
    notification.category = category

    UIApplication.shared.presentLocalNotificationNow(notification)
  }

  fileprivate func secondsToStringOffset(_ jsTime: Double) -> String {
    let offset = Date(timeIntervalSince1970: jsTime / 1000).timeIntervalSince(Date())
    let difference = Date(timeIntervalSince1970: offset - 60*60)
    return difference.toString(format: .custom("mm:ss"))
  }

  //TODO: FIX OLD AND NEW GEOFENCE MODEL!!
  fileprivate func notifyForGeofenceModel(_ oldModel: GeofenceModel, _ updatedModel: GeofenceModel? = nil) {
    assert(Thread.isMainThread)

    let correctModel = updatedModel ?? oldModel

    switch oldModel.type {
    case .start:
      let timeString = secondsToStringOffset(oldModel.fromStop?.time ?? 0)
      var fixedUserInfo = oldModel.encodeJson()
      fixedUserInfo.removeValue(forKey: "toStop")

      fireNotification(
        R.string.localization.startNotificationTitle(),
        body: R.string.localization.startNotificationBody(timeString, oldModel.fromStop?.spoor ?? ""), category: "startStationNotification", userInfo: fixedUserInfo)

    case .tussenStation:
      let timeDiff = oldModel.fromStop?.timeDate.timeIntervalSince(Date()) ?? 0
      let timeString = Date(timeIntervalSince1970: timeDiff).toString(format: .custom("mm:ss"))
      let timeMessage = timeDiff > 0 ? "laat" : "vroeg"
//      fireNotification("Tussen Station", body: "Je bent nu op \(oldModel.fromStop?.name ?? ""), \(timeString) te \(timeMessage)", userInfo: oldModel.encodeJson())

    case .overstap:
      let timeString = secondsToStringOffset(correctModel.fromStop?.time ?? 0)
      fireNotification(R.string.localization.transferNotificationTitle(), body: R.string.localization.transferNotificationBody(correctModel.fromStop?.spoor ?? "", timeString), category: "nextStationNotification", userInfo: ["geofenceModel": oldModel.encodeJson()])

    case .end:
      fireNotification(R.string.localization.endNotificationTitle(), body: R.string.localization.endNotificationBody(), category: nil, userInfo: nil)
    }
  }

  func attach() {
    geofenceService.geofenceObservable?
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] geofenceModel in
        self?.notifyForGeofenceModel(geofenceModel)
      }).addDisposableTo(disposeBag)
  }
}
