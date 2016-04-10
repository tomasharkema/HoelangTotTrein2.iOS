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

  private func fireNotification(title: String, body: String) {
    let notification = UILocalNotification()
    notification.alertTitle = title
    notification.alertBody = body

    notification.soundName = UILocalNotificationDefaultSoundName
    notification.alertAction = "Bekijk"

    UIApplication.sharedApplication().presentLocalNotificationNow(notification)
  }

  private func secondsToStringOffset(jsTime jsTime: Double) -> String {
    let offset = NSDate(timeIntervalSince1970: jsTime / 1000).timeIntervalSinceDate(NSDate())
    let difference = NSDate(timeIntervalSince1970: offset - 60*60)
    return difference.toString(format: .Custom("mm:ss"))
  }
  //TODO: FIX OLD AND NEW GEOFENCE MODEL!!
  private func notifyForGeofenceModel(oldModel: GeofenceModel, _ updatedModel: GeofenceModel) {
    assert(NSThread.isMainThread())
    switch oldModel.type {
    case .Start:
      let timeString = secondsToStringOffset(jsTime: oldModel.fromStop?.time ?? 0)
      fireNotification("Op Station", body: "Je bent op het station. Nog \(timeString)")

    case .TussenStation:
      let timeDiff = oldModel.fromStop?.timeDate.timeIntervalSinceDate(NSDate()) ?? 0
      let timeString = NSDate(timeIntervalSince1970: timeDiff).toString(format: .Custom("mm:ss"))
      let timeMessage = timeDiff > 0 ? "laat" : "vroeg"
      fireNotification("Tussen Station", body: "Je bent nu op \(oldModel.fromStop?.name ?? ""), \(timeString) te \(timeMessage)")

    case .Overstap:
      let timeString = secondsToStringOffset(jsTime: updatedModel.fromStop?.time ?? 0)
      fireNotification("Overstappen!", body: "Stap over naar spoor \(updatedModel.fromStop?.spoor ?? ""). Je hebt nog \(timeString) min")

    case .End:
      fireNotification("Eindstation", body: "Stap hier uit. Vergeet niet uit te checken!")
    }
  }

  func attach() {
    geofenceService.geofenceObservableAfterAdvicesUpdate
      .distinctUntilChanged { $0.lhs.oldModel == $0.rhs.oldModel && $0.lhs.updatedModel == $0.rhs.updatedModel }
      .observeOn(MainScheduler.asyncInstance)
      .subscribeNext { [weak self] (geofenceModel, updatedModel) in
        self?.notifyForGeofenceModel(geofenceModel, updatedModel)
      }.addDisposableTo(disposeBag)
  }
}
