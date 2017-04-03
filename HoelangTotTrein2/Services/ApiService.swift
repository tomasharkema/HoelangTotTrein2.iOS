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
//  let endpoint = "http://mac-server.local:9000"
//  let endpoint = "https://hltt-test.herokuapp.com"

  let queue = DispatchQueue(label: "nl.tomasharkema.DECODE", attributes: DispatchQueue.Attributes.concurrent)

  fileprivate let manager: SessionManager
  fileprivate let networkActivityIndicatorManager: NetworkActivityIndicatorManager

  init() {
    manager = SessionManager.default //URLSessionConfiguration.default
    networkActivityIndicatorManager = NetworkActivityIndicatorManager()
  }

//  fileprivate func requestGet<T>(
//    _ url: URLStringConvertible,
//    parameters: [String: AnyObject]? = nil,
//    encoding: ParameterEncoding,
//    decoder: (AnyObject) throws -> T)
//    -> Promise<T, ErrorResponse<JsonDecodeResponseSerializerError>>
//  {
//    return requestBody(method: .GET, url: url, requestFactory: { req in encoding.encode(req, parameters: parameters).0 }, decoder: decoder)
//  }
//
//  fileprivate func request<T>(
//    _ method: Alamofire.Method,
//    url: URLStringConvertible,
//    parameters: [String: AnyObject]? = nil,
//    encoding: ParameterEncoding,
//    decoder: (AnyObject) throws -> T)
//    -> Promise<T, ErrorResponse>
//  {
//    return self.requestBody(
//      method: method,
//      url: url,
//      requestFactory: { req in encoding.encode(req, parameters: parameters).0 },
//      decoder: decoder)
//  }
//
//  fileprivate func requestBody<T>(
//    _ method: Alamofire.Method,
//    url: URLStringConvertible,
//    requestFactory: (NSMutableURLRequest) -> URLRequest,
//    decoder: (AnyObject) throws -> T)
//    -> Promise<T, ErrorResponse<JsonDecodeResponseSerializerError>>
//  {
//    return self.requestResponse(
//      method: method,
//      url: url,
//      requestFactory: requestFactory,
//      decoder: decoder)
//      .map { $0.result }
//  }

//  fileprivate func makeRequest(_ method: Alamofire.Method, url: URLStringConvertible, requestFactory: (NSMutableURLRequest) -> NSURLRequest) -> Alamofire.Request {
//
//    // Generate a requestId for async logging
//    let requestId = UUID().uuidString
//    let mutableURLRequest = NSMutableURLRequest(URL: URL(string: url.URLString)!)
//
//    mutableURLRequest.HTTPMethod = method.rawValue
//
//    let request = manager.request(requestFactory(mutableURLRequest))
//    
//    let urlDescription = request.request?.URL?.description ?? "nil"
//    log(.DEBUG, section: "API", message: "[RID: \(requestId)]: \(method.rawValue) \(urlDescription)")
//    //log(.DEBUG, section: "API", message: "[RID: \(requestId)]: \(request.debugJsonResponseDescription)")
//
//    // Log responses
//    request.response { (_, response, data, error) in
//      if let resp = response {
//        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: STATUS \(resp.statusCode) \(urlDescription)")
//      }
//      else if let error = error {
//        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: ERROR \(urlDescription) \(error.localizedDescription)")
//      }
//      else {
//        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: EMPTY RESPONSE \(urlDescription)")
//      }
//    }
//
//    return request.validate()
//  }

//  fileprivate func requestResponse<T>(
//    _ method: Alamofire.Method,
//    url: URLStringConvertible,
//    requestFactory: (NSMutableURLRequest) -> URLRequest,
//    decoder: (AnyObject) throws -> T)
//    -> Promise<SuccessResponse<T>, ErrorResponse>
//  {
//    let request = makeRequest(method, url: url, requestFactory: requestFactory)
//    networkActivityIndicatorManager.increment()
//    return request
//      .responseJsonDecodePromise(decoder: decoder)
//      .trap(logServerError)
//      .finally(networkActivityIndicatorManager.decrement)
//  }

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
