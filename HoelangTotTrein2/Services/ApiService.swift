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

struct ApiService {
  let endpoint = "https://ns.harkema.io"

  let queue = DispatchQueue(label: "nl.tomasharkema.DECODE", attributes: DispatchQueue.Attributes.concurrent)

  fileprivate let manager: SessionManager
  fileprivate let networkActivityIndicatorManager: NetworkActivityIndicatorManager

  init() {
    manager = SessionManager.default
    networkActivityIndicatorManager = NetworkActivityIndicatorManager()
  }

  func stations() -> Promise<StationsResponse, Error> {
    return manager.request(
      url: "\(endpoint)/api/stations",
      method: .get,
      parameters: nil,
      headers: [:],
      decoder: StationsResponse.decodeJson)
  }

  func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
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

  func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return manager.request(
      url: "\(endpoint)/api/register/\(URLEncoding.default.escape(userId))",
      method: .get,
      parameters: ["from": from.code, "to": to.code],
      encoding: URLEncoding.default,
      headers: nil,
      decoder: SuccessResult.decodeJson)
  }

  func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
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
