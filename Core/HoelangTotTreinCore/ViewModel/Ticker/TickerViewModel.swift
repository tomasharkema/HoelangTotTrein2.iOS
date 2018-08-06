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

public class ListTickerViewModel {
  private let stateSource = VariableSource<State<Advices>>(value: .loading)
  public let state: Variable<State<Advices>>

  public let currentAdvice: Variable<State<Advice?>>
  public let currentAdvices: Variable<State<Advices>>

  public let fromButtonTitle: Variable<String>
  public let toButtonTitle: Variable<String>

  public let startTime: Variable<Date>

  public init(travelService: TravelService) {
    state = stateSource.variable

    currentAdvice = travelService.currentAdvice
    currentAdvices = travelService.currentAdvices

    startTime = travelService.currentAdvice.map { event in
      return Date()
    }

    fromButtonTitle = travelService.pickedAdviceRequest.map {
      $0.from?.name ?? "[Pick Station]"
    }
    toButtonTitle = travelService.pickedAdviceRequest.map {
      $0.to?.name ?? "[Pick Station]"
    }
  }
}

