//
//  API.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum

public protocol ApiService {
  func stations() -> Promise<StationsResponse, ApiError>
  func advices(for adviceRequest: AdviceRequest) -> Promise<AdvicesResult, ApiError>
}

public enum ApiError: Error {
  case noFullRequest
  case noData
  case external(error: Error)
}
