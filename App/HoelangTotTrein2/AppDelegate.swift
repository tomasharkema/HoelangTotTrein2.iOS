//
//  AppDelegate.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import RxSwift
import Promissum
import HoelangTotTreinAPI
import UserNotifications
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  private var disposeBag = DisposeBag()
  
  internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Fabric.with([Crashlytics.self])

    App.storageAttachment.attach()
    App.travelService.attach()
    _ = App.travelService.fetchStations()
    App.transferService.attach()
    App.notificationService.attach()

    App.appShortcutService.attach()

    requestPush()

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

    App.travelService.currentAdviceOnScreenObservable
      .delaySubscription(5, scheduler: MainScheduler.asyncInstance)
      .take(1)
      .subscribe(onNext: { _ in
        completionHandler(.newData)
      })
      .disposed(by: disposeBag)

    guard let message = userInfo["message"] as? String else {
      return
    }

    let content = UNMutableNotificationContent()
    content.title = R.string.localization.delayed()
    content.badge = 0
    content.body = message

    let request = UNNotificationRequest(identifier: "io.harkema.push.delay", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  private func requestPush() {
    DispatchQueue.main.async { [weak self] in
      UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
        if settings.authorizationStatus == .notDetermined {
          let alert = UIAlertController(title: "Push Notificaties", message: "Deze app kan je een notificatie sturen wanneer je op het station aankomt, of als je op je eindbestemming aankomt. Wil je dit?", preferredStyle: .alert)

          alert.addAction(UIAlertAction(title: "Nu niet", style: .cancel, handler: { _ in
            alert.dismiss(animated: true)
          }))

          alert.addAction(UIAlertAction(title: "Ja doe maar", style: .default, handler: { _ in
            self?.requestAuthorization()
          }))
          
          self?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
      }
    }
  }

  private func requestAuthorization() {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .badge, .sound]
    center.requestAuthorization(options: options) { (_, _) in
    }
  }

}

