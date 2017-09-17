//
//  HttpXmlApiService.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 17-09-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum

final public class HttpXmlApiService: ApiService {

  private let credentials: String

  public init(credentials: String) {
    self.credentials = credentials
  }

  public func stations() -> Promise<StationsResponse, Error> {
    return Promise(error: ApiError.notImplemented)
  }

  public func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    return Promise(error: ApiError.notImplemented)
  }

  public func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return Promise(error: ApiError.notImplemented)
  }

  public func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
    return Promise(error: ApiError.notImplemented)
  }
}
