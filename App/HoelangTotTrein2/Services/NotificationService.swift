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
import HoelangTotTreinCore
import UserNotifications

class NotificationService {
  private let transferService: TransferService
  private let dataStore: DataStore
  private let apiService: ApiService
  fileprivate let disposeBag = DisposeBag()

  init(transferService: TransferService, dataStore: DataStore, apiService: ApiService) {
    self.transferService = transferService
    self.dataStore = dataStore
    self.apiService = apiService
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
    content.sound = UNNotificationSound.default()

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    let center = UNUserNotificationCenter.current()
    center.add(request, withCompletionHandler: nil)
  }

  fileprivate func secondsToStringOffset(_ jsTime: Double) -> String {
    let components = Calendar.current.dateComponents([.minute, .second], from: Date(), to: Date(timeIntervalSince1970: jsTime / 1000))
    guard let minutes = components.minute, let seconds = components.second else {
      return "0:00"
    }

    return String(format: "%02d:%02d", minutes, seconds)
  }

  //TODO: FIX OLD AND NEW GEOFENCE MODEL!!
  fileprivate func notifyForGeofenceModel(_ oldModel: GeofenceModel, _ updatedModel: GeofenceModel? = nil) {
    assert(Thread.isMainThread)

    let correctModel = updatedModel ?? oldModel



    switch oldModel.type {
    case .start:
      let timeString = secondsToStringOffset(oldModel.stop.time)

      do {
        var fixedUserInfo = try oldModel.encodeJson() as? [String: Any] ?? [:]
        fixedUserInfo.removeValue(forKey: "toStop")

        fireNotification(
          "io.harkema.notification.start",
          title: R.string.localization.startNotificationTitle(),
          body: R.string.localization.startNotificationBody(timeString, oldModel.stop.spoor ?? ""),
          categoryIdentifier: "startStationNotification",
          userInfo: fixedUserInfo)
      } catch {
        print("ERROR \(error)")
      }
    case .tussenStation:
      break

    case .overstap:
      do {

        if (correctModel.stop.timeDate.timeIntervalSinceNow) < 0 {
          return
        }

        let timeString = secondsToStringOffset(correctModel.stop.time)
        fireNotification(
          "io.harkema.notification.overstap",
          title: R.string.localization.transferNotificationTitle(),
          body: R.string.localization.transferNotificationBody(correctModel.stop.spoor ?? "", timeString),
          categoryIdentifier: "nextStationNotification",
          userInfo: ["geofenceModel": try oldModel.encodeJson()])
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

  func attach() {
    transferService.geofenceObservable?
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] geofenceModel in
        self?.notifyForGeofenceModel(geofenceModel)
      }).addDisposableTo(disposeBag)
  }

  func register(token deviceToken: Data) {
    #if RELEASE
      let env = "production"
    #else
      let env = "sandbox"
    #endif
    var token = ""
    for i in 0..<deviceToken.count {
      token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
    }

    apiService.registerForNotification(dataStore.userId, env: env, pushUUID: token)
      .then {
        print("ApiService did registerForNotification \($0)")
      }
      .trap {
        print($0)
    }
  }
}
