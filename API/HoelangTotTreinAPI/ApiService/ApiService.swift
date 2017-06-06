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

extension String: URLRequestConvertible {
  public func asURLRequest() throws -> URLRequest {
    guard let url = URL(string: self) else {
      throw NSError(domain: "", code: 0, userInfo: nil)
    }

    return URLRequest(url: url)
  }
}

public protocol ApiService {
  func stations() -> Promise<StationsResponse, Error>
  func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error>
  func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error>
  func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error>
}

public class HttpApiService: ApiService {
  private let endpoint: String

  private let manager = Alamofire.SessionManager.default

  public init(endpoint: String) {
    self.endpoint = endpoint
  }

  public func stations() -> Promise<StationsResponse, Error> {
    return manager.requestWithDecoder(
      url: "\(endpoint)/api/stations",
      decoderType: StationsResponse.self)
  }

  public func advices(_ adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    guard let from = adviceRequest.from?.code, let to = adviceRequest.to?.code else {
      return Promise(error: NSError(domain: "Geen volledige request", code: 100, userInfo: nil))
    }

    return manager.requestWithDecoder(
      url: "\(endpoint)/api/advices",
      parameters: ["from": from, "to": to],
      decoderType: AdvicesResult.self)
  }

  public func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return manager.requestWithDecoder(
      url: "\(endpoint)/api/register/\(URLEncoding.default.escape(userId))",
      parameters: ["from": from.code, "to": to.code],
      decoderType: SuccessResult.self)
  }

  public func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
    let url = "\(endpoint)/api/register/\(userId)/PUSH/\(pushUUID)?env=\(env)"

    return manager.requestWithDecoder(
      url: url,
      decoderType: SuccessResult.self)
  }
}
