//
//  API.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Promissum
import Alamofire
import Foundation

struct ApiService {
  let endpoint = "http://ns.harkema.in"
//  let endpoint = "http://mac-server.local:9000"
//  let endpoint = "https://hltt-test.herokuapp.com"

  let queue = dispatch_queue_create("nl.tomasharkema.DECODE", DISPATCH_QUEUE_CONCURRENT)
  
  private let manager: Manager
  private let networkActivityIndicatorManager: NetworkActivityIndicatorManager

  init() {
    manager = Manager()
    networkActivityIndicatorManager = NetworkActivityIndicatorManager()
  }

  private func requestGet<T>(
    url: URLStringConvertible,
    parameters: [String: AnyObject]? = nil,
    encoding: ParameterEncoding,
    decoder: AnyObject throws -> T)
    -> Promise<T, ErrorResponse<JsonDecodeResponseSerializerError>>
  {
    return requestBody(method: .GET, url: url, requestFactory: { req in encoding.encode(req, parameters: parameters).0 }, decoder: decoder)
  }

  private func request<T>(
    method method: Alamofire.Method,
    url: URLStringConvertible,
    parameters: [String: AnyObject]? = nil,
    encoding: ParameterEncoding,
    decoder: AnyObject throws -> T)
    -> Promise<T, ErrorResponse<JsonDecodeResponseSerializerError>>
  {
    return self.requestBody(
      method: method,
      url: url,
      requestFactory: { req in encoding.encode(req, parameters: parameters).0 },
      decoder: decoder)
  }

  private func requestBody<T>(
    method method: Alamofire.Method,
    url: URLStringConvertible,
    requestFactory: NSMutableURLRequest -> NSURLRequest,
    decoder: AnyObject throws -> T)
    -> Promise<T, ErrorResponse<JsonDecodeResponseSerializerError>>
  {
    return self.requestResponse(
      method: method,
      url: url,
      requestFactory: requestFactory,
      decoder: decoder)
      .map { $0.result }
  }

  private func makeRequest(method: Alamofire.Method, url: URLStringConvertible, requestFactory: NSMutableURLRequest -> NSURLRequest) -> Alamofire.Request {

    // Generate a requestId for async logging
    let requestId = NSUUID().UUIDString
    let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url.URLString)!)

    mutableURLRequest.HTTPMethod = method.rawValue

    let request = manager.request(requestFactory(mutableURLRequest))
    
    let urlDescription = request.request?.URL?.description ?? "nil"
    log(.DEBUG, section: "API", message: "[RID: \(requestId)]: \(method.rawValue) \(urlDescription)")
    //log(.DEBUG, section: "API", message: "[RID: \(requestId)]: \(request.debugJsonResponseDescription)")

    // Log responses
    request.response { (_, response, data, error) in
      if let resp = response {
        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: STATUS \(resp.statusCode) \(urlDescription)")
      }
      else if let error = error {
        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: ERROR \(urlDescription) \(error.localizedDescription)")
      }
      else {
        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: EMPTY RESPONSE \(urlDescription)")
      }
    }

    return request.validate()
  }

  private func requestResponse<T>(
    method method: Alamofire.Method,
    url: URLStringConvertible,
    requestFactory: NSMutableURLRequest -> NSURLRequest,
    decoder: AnyObject throws -> T)
    -> Promise<SuccessResponse<T>, ErrorResponse<JsonDecodeResponseSerializerError>>
  {
    let request = makeRequest(method, url: url, requestFactory: requestFactory)
    networkActivityIndicatorManager.increment()
    return request
      .responseJsonDecodePromise(decoder: decoder)
      .trap(logServerError)
      .finally(networkActivityIndicatorManager.decrement)
  }

  private func logServerError<T: ErrorType>(error: ErrorResponse<T>) {

    if let serverError = error.decode(statusCode: 500, decoder: ServerErrorJson.decodeJson) {
      log(.ERROR, section: "API", message: "Server error: \(serverError.exceptionMessage ?? serverError.message)")
    }
  }

  func stations() -> Promise<StationsResponse, ErrorType> {
    let url = "\(endpoint)/api/stations"
    return requestGet(url, encoding: .URL, decoder: StationsResponse.decodeJson)
      .mapErrorType()
  }

  func advices(adviceRequest: AdviceRequest) -> Promise<AdvicesResult, ErrorType> {
    if let from = adviceRequest.from?.code, to = adviceRequest.to?.code {
      let url = "\(endpoint)/api/advices?from=\(from)&to=\(to)"
      return requestGet(url, encoding: .URL, decoder: AdvicesResult.decodeJson)
        .mapErrorType()
    }

    return Promise(error: NSError(domain: "Geen volledige request", code: 100, userInfo: nil))
  }

  func registerForNotification(userId: String, from: Station, to: Station) -> Promise<SuccessResult, ErrorType> {
    let url = "\(endpoint)/api/register/\(userId)?from=\(from.code)&to=\(to.code)"
    return requestGet(url, encoding: .URL, decoder: SuccessResult.decodeJson)
      .mapErrorType()
  }

  func registerForNotification(userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, ErrorType> {
    let url = "\(endpoint)/api/register/\(userId)/PUSH/\(pushUUID)?env=\(env)"
    return requestGet(url, encoding: .URL, decoder: SuccessResult.decodeJson)
      .mapErrorType()
  }
}