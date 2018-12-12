//
//  NotificationService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 24-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import UIKit
import Bindable

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif
import HoelangTotTreinCore
import UserNotifications

class NotificationService: NSObject {
  private let transferService: TransferService
  private let dataStore: DataStore
  private let preferenceStore: PreferenceStore
  private let apiService: ApiService

  private var currentGeofence: GeofenceModel? {
    didSet {
      guard let currentGeofence = currentGeofence,
        currentGeofence.type == .overstap,
        preferenceStore.appSettings.contains(.transferNotificationEnabled)
        else {
          return
        }

      notify(for: currentGeofence)
    }
  }

  init(transferService: TransferService, dataStore: DataStore, preferenceStore: PreferenceStore, apiService: ApiService) {
    self.transferService = transferService
    self.dataStore = dataStore
    self.preferenceStore = preferenceStore
    self.apiService = apiService

    super.init()

    start()
  }

  private func start() {
    bind(\.currentGeofence, to: transferService.geofence)
  }

  fileprivate func fireNotification(_ identifier: String, title: String, body: String, categoryIdentifier: String?, userInfo: [String: Any]?) {

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    if let categoryIdentifier = categoryIdentifier {
      content.categoryIdentifier = categoryIdentifier
    }
    if let userInfo = userInfo {
      content.userInfo = userInfo
    }
    content.sound = UNNotificationSound.default

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    let center = UNUserNotificationCenter.current()
    center.add(request, withCompletionHandler: nil)
  }

  fileprivate func secondsToStringOffset(_ date: Date) -> String {
    let components = Calendar.current.dateComponents([.minute, .second], from: Date(), to: date)
    guard let minutes = components.minute, let seconds = components.second else {
      return "0:00"
    }

    return String(format: "%02d:%02d", minutes, seconds)
  }

  fileprivate func notify(for model: GeofenceModel) {
    assert(Thread.isMainThread)

    guard let time = model.stop.time else {
      return
    }
    
    switch model.type {
    case .start:
      let timeString = secondsToStringOffset(time)

      do {
        fireNotification(
          "io.harkema.notification.start",
          title: R.string.localization.startNotificationTitle(),
          body: R.string.localization.startNotificationBody(timeString, model.stop.halt?.plannedDepartureTrack ?? ""),
          categoryIdentifier: "nextStationNotification",
          userInfo: ["geofenceModel": try model.encodeJson()])
      } catch {
        print("ERROR \(error)")
      }
    case .tussenStation:
      break

    case .overstap:
      do {

        guard time > Date() else {
          return
        }

        let timeString = secondsToStringOffset(time)
        fireNotification(
          "io.harkema.notification.overstap",
          title: R.string.localization.transferNotificationTitle(),
          body: R.string.localization.transferNotificationBody(model.stop.halt?.plannedDepartureTrack ?? "", timeString),
          categoryIdentifier: "nextStationNotification",
          userInfo: ["geofenceModel": try model.encodeJson()])
      } catch {
        print("Error: \(error)")
      }

    case .end:
      fireNotification(
        "io.harkema.notification.end",
        title: R.string.localization.endNotificationTitle(),
        body: R.string.localization.endNotificationBody(),
        categoryIdentifier: nil,
        userInfo: nil)
    }
  }
}
