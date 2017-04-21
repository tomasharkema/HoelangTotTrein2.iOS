//
//  SessionManager+Request.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 01-04-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Alamofire
import Statham
import Promissum

extension SessionManager {
  func request<DecodedResponse>(
    url: URLConvertible,
    method: HTTPMethod,
    parameters: Parameters?,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil,
    decoder: @escaping (Any) throws -> DecodedResponse)
    -> Promise<DecodedResponse, Error>
  {
    let request = self
      .request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
      .validate()

    print(request.debugDescription)

    return request
      .responseJsonDecodePromise(decoder: decoder)
      .trap { error in
        debugPrint("vvv")
        debugPrint(request)
        debugPrint("---")
        debugPrint(error)
        debugPrint("^^^")
      }
      .mapError()
      .map { $0.result }
  }
}
