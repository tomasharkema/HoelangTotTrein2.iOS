//
//  AppShortcutService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 05-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift
import HoelangTotTreinAPI
import HoelangTotTreinCore

class AppShortcutService {
  private let travelService: TravelService
  private let disposeBag = DisposeBag()

  init(travelService: TravelService) {
    self.travelService = travelService
  }

  func attach() {
    travelService.mostUsedStationsObservable
      .filter { !$0.isEmpty }
      .subscribe(onNext: { stations in
        self.showAppShortcuts(forStations: stations)
      })
      .disposed(by: disposeBag)
  }

  private func showAppShortcuts(forStations stations: [Station]) {
    UIApplication.shared.shortcutItems?.removeAll()

    let firstStations = stations.prefix(4)

    let shortcuts: [UIApplicationShortcutItem] = firstStations.map { station in
      let icon = UIApplicationShortcutIcon(type: .favorite)
      return UIMutableApplicationShortcutItem(type: "nl.tomasharkema.HoelangTotTrein.stationshortcut", localizedTitle: station.name, localizedSubtitle: nil, icon: icon, userInfo: ["stationCode": station.code as NSSecureCoding])
    }

    UIApplication.shared.shortcutItems = shortcuts
  }

}

extension AppDelegate {
  func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    App.travelService.tick()

    guard let stationCode = shortcutItem.userInfo?["stationCode"] as? String else {
      completionHandler(false)
      return
    }

    App.travelService.setStation(.to, stationCode: stationCode)
      .flatMap { _ in App.travelService.travelFromCurrentLocation() }
      .then { _ in
        completionHandler(true)
      }
      .trap { error in
        print(error)
        completionHandler(false)
      }
  }
}

