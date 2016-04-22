//
//  AppDelegate.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import CoreDataKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var disposeBag = DisposeBag()
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.

    NewRelic.startWithApplicationToken("AA37eca143a6cbc43c025498e41838d785d5666a06")

    if let persistentStoreCoordinator = NSPersistentStoreCoordinator(automigrating: true) {
      CDK.sharedStack = CoreDataStack(persistentStoreCoordinator: persistentStoreCoordinator)
    }

    App.storageAttachment.attach(CDK.backgroundContext)
    App.travelService.attach()
    App.travelService.fetchStations()
    App.notificationService.attach()

    application.registerForRemoteNotifications()
    application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))

    return true
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
  }

  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    let pushUUID = deviceToken.description
    #if RELEASE
    let env = "production"
    #else
    let env = "sandbox"
    #endif
    
    App.apiService.registerForNotification(UserDefaults.userId, env: env, pushUUID:
      pushUUID
        .stringByReplacingOccurrencesOfString("<", withString: "")
        .stringByReplacingOccurrencesOfString(">", withString: "")
        .stringByReplacingOccurrencesOfString(" ", withString: "")
    ).then {
      print($0)
    }.trap {
      print($0)
    }
  }

  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    App.travelService.attach()
    App.travelService.tick()
    App.travelService.currentAdviceOnScreenVariable.asObservable().delaySubscription(10, scheduler: MainScheduler.asyncInstance).single().subscribeNext { _ in
      completionHandler(.NewData)
    }.addDisposableTo(disposeBag)
  }
}

