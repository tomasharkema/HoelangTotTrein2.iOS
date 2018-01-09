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

extension DataRequest {
  static func jsonDecodableResponseSerializer<T: Decodable>(decoderType: T.Type) -> DataResponseSerializer<T>
  {
    return DataResponseSerializer { (request, response, data, error) in
      guard let data = data else {
        assertionFailure("NO DATA")
        return .failure(NSError(domain: "DataRequestNoData", code: 0, userInfo: nil))
      }

      let decoder = JSONDecoder()
      do {
        return .success(try decoder.decode(decoderType, from: data))
      } catch {
        return .failure(error)
      }
    }
  }
}

extension SessionManager {
  func requestWithDecoder<DecodedResponse: Decodable>(
    url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil,
    decoderType: DecodedResponse.Type)
    -> Promise<DecodedResponse, Error>
  {
    let request = self
      .request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
      .validate()

    print(request.debugDescription)

    return request
      .responsePromise(responseSerializer: DataRequest.jsonDecodableResponseSerializer(decoderType: decoderType))
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
