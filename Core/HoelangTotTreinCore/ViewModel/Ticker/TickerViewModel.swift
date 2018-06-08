//
//  TickerViewModel.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-06-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation
import Bindable

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#elseif canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif

struct TickerViewModel {
  private let adviceSource = VariableSource<Advice?>(value: nil)
  let advice: Variable<Advice?>

  init() {
    advice = adviceSource.variable
  }
}
