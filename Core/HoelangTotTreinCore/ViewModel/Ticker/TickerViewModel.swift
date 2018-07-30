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

  public let fromIndicator: Variable<String>//(value: "[Pick Station]")
  public let toIndicator: Variable<String>//(value: "[Pick Station]")

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

//    //TODO: fix
    let fromIndicatorSource = VariableSource<String>(value: "[Pick Station]")
    let toIndicatorSource = VariableSource<String>(value: "[Pick Station]")
    fromIndicator = fromIndicatorSource.variable
    toIndicator = fromIndicatorSource.variable

    travelService.getCurrentAdviceRequest()
      .then {
        fromIndicatorSource.setValue($0.from?.name ?? "[Pick Station]", animated: false)
        toIndicatorSource.setValue($0.to?.name ?? "[Pick Station]", animated: false)
      }
      .trap {
        print("\($0)")
      }
  }

}

