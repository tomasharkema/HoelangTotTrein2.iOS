//
//  API.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import CancellationToken
import Foundation
import Promissum

public protocol ApiService {
  func stations(cancellationToken: CancellationToken?) -> Promise<StationsResponse, ApiError>
  func advices(for adviceRequest: AdviceRequest, scrollRequestForwardContext: String?, cancellationToken: CancellationToken?) -> Promise<AdvicesResponse, ApiError>
}

public enum ApiError: Error {
  case noFullRequest
  case noData
  case external(error: Error)
}
