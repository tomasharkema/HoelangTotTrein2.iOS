//
//  API.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import Alamofire
import Statham

public protocol ApiService {
  func stations() -> Promise<StationsResponse, Error>
  func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error>
  func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error>
  func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error>
}

public class HttpApiService: ApiService {
  private let endpoint: String

  fileprivate let manager: SessionManager

  public init(endpoint: String) {
    self.endpoint = endpoint
    manager = SessionManager.default
  }

  public func stations() -> Promise<StationsResponse, Error> {
    return manager.request(
      url: "\(endpoint)/api/stations",
      method: .get,
      parameters: nil,
      headers: [:],
      decoder: StationsResponse.decodeJson)
  }

  public func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    guard let from = adviceRequest.from?.code, let to = adviceRequest.to?.code else {
      return Promise(error: NSError(domain: "Geen volledige request", code: 100, userInfo: nil))
    }

    return manager.request(
      url: "\(endpoint)/api/advices",
      method: .get,
      parameters: ["from": from, "to": to],
      headers: [:],
      decoder: AdvicesResult.decodeJson)
  }

  public func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return manager.request(
      url: "\(endpoint)/api/register/\(URLEncoding.default.escape(userId))",
      method: .get,
      parameters: ["from": from.code, "to": to.code],
      encoding: URLEncoding.default,
      headers: nil,
      decoder: SuccessResult.decodeJson)
  }

  public func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
    let url = "\(endpoint)/api/register/\(userId)/PUSH/\(pushUUID)?env=\(env)"

    return manager.request(
      url: url,
      method: .get,
      parameters: nil,
      encoding: URLEncoding.default,
      headers: nil,
      decoder: SuccessResult.decodeJson)
  }
}
