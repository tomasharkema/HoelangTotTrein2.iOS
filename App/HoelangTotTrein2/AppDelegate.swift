//
//  AppDelegate.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import Promissum

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif
import UserNotifications
import Firebase
import SwiftUI
import Bindable
import Combine

//class TimerHolder: BindableObject {
//  var timer : Timer!
//  let willChange = PassthroughSubject<TimerHolder,Never>()
//  var count = 0 {
//    didSet {
//      self.willChange.send(self)
//    }
//  }
//  func start() {
//    self.timer?.invalidate()
//    self.count = 0
//
//    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
//      _ in
//      self.count += 1
//    }
//    self.timer.tolerance = 1/60
//  }
//}

class HostingController<ContentView: View>: UIHostingController<ContentView> {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    D().joe()
    
    FirebaseApp.configure()
    App.storageAttachment
    _ = App.travelService.fetchStations()
    App.transferService
    App.notificationService

    App.appShortcutService

    DispatchQueue.main.async { [weak self] in
      self?.requestPush()
    }

    if #available(iOS 13, *) {

      let adviceStations = VariableBindable(variable: App.travelService.adviceStations)
      let currentAdvices = App.travelService.currentAdvices.map {
        $0.value
      }
      let advices = VariableBindable(variable: currentAdvices)
      let mostUsedStations = VariableBindable(variable: App.travelService.mostUsedStations.map {
        MostUsedStations(stations: $0)
      })
      let stations = VariableBindable(variable: App.travelService.stations)

      //      let holder = TimerHolder()
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = HostingController(rootView: ContentView()
        .environmentObject(stations)
        .environmentObject(advices)
        .environmentObject(adviceStations)
        .environmentObject(mostUsedStations)
      )
      window?.makeKeyAndVisible()
    }
    
    return true
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    App.heartBeat.isSuspended = true
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    App.heartBeat.isSuspended = false
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
  }

  //  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  //
  //    App.travelService.currentAdviceOnScreenObservable
  //      .delaySubscription(5, scheduler: MainScheduler.asyncInstance)
  //      .take(1)
  //      .subscribe(onNext: { _ in
  //        completionHandler(.newData)
  //      })
  //      .disposed(by: bag)
  //
  //    guard let message = userInfo["message"] as? String else {
  //      return
  //    }
  //
  //    let content = UNMutableNotificationContent()
  //    content.title = R.string.localization.delayed()
  //    content.badge = 0
  //    content.body = message
  //
  //    let request = UNNotificationRequest(identifier: "io.harkema.push.delay", content: content, trigger: nil)
  //    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  //  }

  private func requestPush() {

    UNUserNotificationCenter.current().notificationSettings()
      .then { [weak self] settings in
        if settings.authorizationStatus == .notDetermined {
          let alert = UIAlertController(title: "Push Notificaties", message: "Deze app kan je een notificatie sturen als je op je eindbestemming aankomt. Wil je dit?", preferredStyle: .alert)

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

  private func requestAuthorization() {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .badge, .sound]
    center.requestAuthorization(options: options) { (_, _) in
    }
  }

}

