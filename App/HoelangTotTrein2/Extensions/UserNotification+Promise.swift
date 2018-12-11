//
//  UserNotification+Promise.swift
//  
//
//  Created by Tomas Harkema on 26/09/2018.
//

import Foundation
import UserNotifications
import Promissum

extension UNUserNotificationCenter {
  func notificationSettings() -> Promise<UNNotificationSettings, NoError> {
    let promiseSource = PromiseSource<UNNotificationSettings, NoError>()

    getNotificationSettings { settings in
      promiseSource.resolve(settings)
    }

    return promiseSource.promise
  }
}
