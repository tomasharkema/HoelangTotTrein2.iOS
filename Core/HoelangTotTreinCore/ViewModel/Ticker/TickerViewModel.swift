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

public enum State<Result> {
  case loading
  case error(Error)
  case result(Result)
}

public class ListTickerViewModel {
  private let stateSource = VariableSource<State<Advices>>(value: .loading)
  public let state: Variable<State<Advices>>

  public let currentAdvice: Variable<State<Advice?>>

  public let fromButtonTitle: Variable<String>
  public let toButtonTitle: Variable<String>

  public init(travelService: TravelService) {
    state = stateSource.variable

    currentAdvice = state.map {
      switch $0 {
      case .error(let error):
        return .error(error)
      case .loading:
        return .loading
      case .result(let result):
        return .result(result.first)
      }
    }

    fromButtonTitle = travelService.currentAdviceRequest.map { $0.from?.name ?? "[Pick Station]" }
    toButtonTitle = travelService.currentAdviceRequest.map { $0.to?.name ?? "[Pick Station]" }
  }

}

