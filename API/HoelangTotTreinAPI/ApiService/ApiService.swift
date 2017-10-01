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
  func advices(for adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error>
  func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error>
  func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error>
}

enum ApiError: Error {
  case notImplemented
  case noFullRequest
}
