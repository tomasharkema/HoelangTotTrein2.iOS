//
//  AppDataStore.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 08-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import HoelangTotTreinAPIWatch
import WatchKit

class AppDataStore {

  func getCurrentAdvice() -> Advice? {
    let currentHash = (WKExtension.shared().delegate as? ExtensionDelegate)?.cachedAdviceIdentifier //?? currentAdviceHash//currentAdviceHash
    let advices = (WKExtension.shared().delegate as? ExtensionDelegate)?.cachedAdvices ?? persistedAdvices

    let adviceOpt = advices?.filter {
      $0.identifier() == currentHash && $0.isOngoing
    }.first ?? advices?.filter {
      $0.isOngoing
    }.first

    return adviceOpt
  }
}
