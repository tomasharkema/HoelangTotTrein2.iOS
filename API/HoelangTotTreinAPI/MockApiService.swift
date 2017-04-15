//
//  MockApiService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 15-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum

class MockApiService: ApiService {

  func stations() -> Promise<StationsResponse, Error> {
    return Promise(value: StationsResponse(stations: []))
  }

  func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    return Promise(value: AdvicesResult(advices: []))
  }

  func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return Promise(value: SuccessResult(success: true))
  }

  func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
    return Promise(value: SuccessResult(success: true))
  }
}
