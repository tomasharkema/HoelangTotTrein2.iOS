//
//  AppShortcutService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 05-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
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

class AppShortcutService: NSObject {
  private let travelService: TravelService

  private var mostUsedStations: Stations? {
    didSet {
      showAppShortcuts(forStations: mostUsedStations ?? [])
    }
  }

  init(travelService: TravelService) {
    self.travelService = travelService

    super.init()

    start()
  }

  private func start() {
    bind(\.mostUsedStations, to: travelService.mostUsedStations)
  }

  private func showAppShortcuts(forStations stations: [Station]) {
    UIApplication.shared.shortcutItems?.removeAll()

    let firstStations = stations.prefix(4)

    let shortcuts: [UIApplicationShortcutItem] = firstStations.map { station in
      let icon = UIApplicationShortcutIcon(type: .favorite)
      return UIMutableApplicationShortcutItem(type: "nl.tomasharkema.HoelangTotTrein.stationshortcut", localizedTitle: station.name, localizedSubtitle: nil, icon: icon, userInfo: ["uiccode": station.UICCode.rawValue as NSSecureCoding])
    }

    UIApplication.shared.shortcutItems = shortcuts
  }

}

extension AppDelegate {
  func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    App.travelService.tick(userInteraction: false)

    guard let stationCode = shortcutItem.userInfo?["uiccode"] as? String else {
      completionHandler(false)
      return
    }

    App.travelService.setStation(.to, byPicker: true, uicCode: UicCode(rawValue: stationCode))
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

