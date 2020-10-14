//
//  AdviceCellViewModel.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 26/09/2018.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import API
import Foundation

struct AdviceCellViewModel {
  private let advice: Advice

  init(advice: Advice) {
    self.advice = advice
  }
}
