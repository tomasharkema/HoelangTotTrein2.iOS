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
      .addDisposableTo(disposeBag)
  }

  private func showAppShortcuts(forStations stations: [Station]) {
    UIApplication.shared.shortcutItems?.removeAll()

    let firstStations = stations.prefix(4)

    let shortcuts: [UIApplicationShortcutItem] = firstStations.map { station in
      let icon = UIApplicationShortcutIcon(type: .favorite)
      return UIMutableApplicationShortcutItem(type: "nl.tomasharkema.HoelangTotTrein.stationshortcut", localizedTitle: station.name, localizedSubtitle: nil, icon: icon, userInfo: ["station": station.encodeJson()])
    }

    UIApplication.shared.shortcutItems = shortcuts
  }

}

