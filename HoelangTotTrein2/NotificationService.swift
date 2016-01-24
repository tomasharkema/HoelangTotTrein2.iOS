//
//  NotificationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit

class NotificationService {
  let geofenceService: GeofenceService

  var geofenceSubscription: ObservableSubject<GeofenceModel>!

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

  private func secondsToStringOffset(time: Double) -> String {
    let offset = NSDate(timeIntervalSince1970: time).timeIntervalSinceDate(NSDate())
    let difference = NSDate(timeIntervalSince1970: offset - 60*60)
    return difference.toString(format: .Custom("mm:ss"))
  }

  private func notifyForGeofenceModel(geofenceModel: GeofenceModel) {

    switch geofenceModel.type {
    case .Start:
      let timeString = secondsToStringOffset(geofenceModel.fromStop?.time ?? 0)
      fireNotification("Op Station", body: "Je bent op het station. Nog \(timeString)")

    case .TussenStation:
      fireNotification("Tussen Station", body: "Je bent nu op \(geofenceModel.fromStop?.name ?? "")")

    case .Overstap:
      let timeString = secondsToStringOffset(geofenceModel.toStop?.time ?? 0)
      fireNotification("Overstappen!", body: "Stap over naar spoor \(geofenceModel.toStop?.spoor ?? ""). Je hebt nog \(timeString) min")

    case .End:
      fireNotification("Eindstation", body: "Stap hier uit. Vergeet niet uit te checken!")

    }

  }

  func attach() {
    geofenceSubscription = geofenceService.geofenceObservable.subscribe { [weak self] geofenceModel in
      self?.notifyForGeofenceModel(geofenceModel)
    }
  }

  deinit {
    geofenceService.geofenceObservable.unsubscribe(geofenceSubscription)
  }
}
