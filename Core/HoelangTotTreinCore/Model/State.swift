//
//  State.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 05-08-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation

public enum State<Result> {
  case loading
  case error(Error)
  case result(Result)

  public var value: Result? {
    switch self {
    case .result(let value):
      return value
    case .loading, .error:
      return nil
    }
  }
}
