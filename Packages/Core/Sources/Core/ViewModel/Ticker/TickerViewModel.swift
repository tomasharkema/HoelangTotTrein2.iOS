//
//  TickerViewModel.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 08-06-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import API
import Bindable
import Foundation

public class ListTickerViewModel {
  private let stateSource = VariableSource<LoadingState<Advices>>(value: .loading)
  public let state: Variable<LoadingState<Advices>>

  public let currentAdvice: Variable<LoadingState<Advice?>>
  public let currentAdvices: Variable<LoadingState<AdvicesAndRequest>>

  public let fromButtonTitle: Variable<String>
  public let toButtonTitle: Variable<String>

  public let startTime: Variable<Date>

  public init(travelService: TravelService) {
    state = stateSource.variable

    currentAdvice = travelService.currentAdvice
    currentAdvices = travelService.currentAdvices

    startTime = travelService.currentAdvice.map { _ in
      Date()
    }

    fromButtonTitle = travelService.adviceStations.map {
      $0.from ?? "[Pick Station]"
    }
    toButtonTitle = travelService.adviceStations.map {
      $0.to ?? "[Pick Station]"
    }
  }
}
