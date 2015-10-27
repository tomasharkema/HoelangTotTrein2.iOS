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
  let endpoint = "https://hltt-test.herokuapp.com"
  let queue = dispatch_queue_create("nl.tomasharkema.DECODE", DISPATCH_QUEUE_CONCURRENT)
  
  private let manager: Manager
  private let networkActivityIndicatorManager: NetworkActivityIndicatorManager

  init() {
    manager = Manager()
    networkActivityIndicatorManager = NetworkActivityIndicatorManager()
  }

  // MARK: Generic error handlers

//  private func logServerError(error: AlamofirePromiseError) {
//    switch error {
//    case let .HttpError(status: 500, result: result):
//      if let resultValue = result?.value, serverError = ServerErrorJson.decodeJson(resultValue) {
//        log(.ERROR, section: "API", message: "Server error: \(serverError.exceptionMessage ?? serverError.message)")
//      }
//    default:
//      break
//    }
//  }

  private func requestGet<T>(url: URLStringConvertible, parameters: [String: AnyObject]? = nil, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return request(.GET, url: url, parameters: parameters, encoding: .URL, decoder: decoder)
  }

  private func request<T>(method: Alamofire.Method, url: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {
    return self.requestBody(method, url: url, requestFactory: { req in encoding.encode(req, parameters: parameters).0 }, decoder: decoder)

  }

  private func handleAppErrors<T>(error: AlamofirePromiseError) -> Promise<T, ErrorType> {
    return Promise(error: error)
  }

  private func requestBody<T>(method: Alamofire.Method, url: URLStringConvertible, requestFactory: NSMutableURLRequest -> NSURLRequest, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {

    // Generate a requestId for async logging
    let requestId = NSUUID().UUIDString
    let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url.URLString)!)

    mutableURLRequest.HTTPMethod = method.rawValue
//    mutableURLRequest.setValue(NSUserDefaults.standardUserDefaults().deviceId, forHTTPHeaderField: "Device-Token")
//    mutableURLRequest.setValue("\(version.rawValue)", forHTTPHeaderField: "api-version")
//    mutableURLRequest.setValue(NSBundle.mainBundle().shortVersion, forHTTPHeaderField: "PostNL-App-Version")
//    mutableURLRequest.setValue("\(UIDevice.currentDevice().systemName) (\(UIDevice.currentDevice().systemVersion))", forHTTPHeaderField: "PostNL-App-Platform")

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
        //log(.DEBUG, section: "API", message: "[RID: \(requestId)]: ERROR \(urlDescription) \(toNSError(error).localizedDescription)")
      }
      else {
        log(.DEBUG, section: "API", message: "[RID: \(requestId)]: EMPTY RESPONSE \(urlDescription)")
      }
    }

    networkActivityIndicatorManager.increment()

    return request
      .responseDecodePromise(queue, decoder: decoder)
      //.trap(logServerError
      .finally(networkActivityIndicatorManager.decrement)
  }

  func stations() -> Promise<StationsResponse, AlamofirePromiseError> {
    let url = "\(endpoint)/api/stations"
    return requestGet(url, decoder: StationsResponse.decodeJson)
  }

  func advices(adviceRequest: AdviceRequest) -> Promise<AdvicesResult, ErrorType> {
    if let from = adviceRequest.from?.code, to = adviceRequest.to?.code {
      let url = "\(endpoint)/api/advices/future?from=\(from)&to=\(to)"

      return requestGet(url, decoder: AdvicesResult.decodeJson)
        .flatMapError(handleAppErrors)
    }

    return Promise(error: NSError(domain: "Geen volledige request", code: 100, userInfo: nil))
  }

  func registerForNotification(userId: String, from: Station, to: Station) -> Promise<SuccessResult, ErrorType> {
    let url = "\(endpoint)/api/register/\(userId)?from=\(from.code)&to=\(to.code)"
    return requestGet(url, decoder: SuccessResult.decodeJson)
      .flatMapError(handleAppErrors)
  }

  func registerForNotification(userId: String, pushUUID: String) -> Promise<SuccessResult, ErrorType> {
    let url = "\(endpoint)/api/register/\(userId)/PUSH/\(pushUUID)"
    return requestGet(url, decoder: SuccessResult.decodeJson)
      .flatMapError(handleAppErrors)
  }
}