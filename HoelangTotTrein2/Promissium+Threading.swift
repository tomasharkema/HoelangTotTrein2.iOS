//
//  Promissium+Threading.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import Alamofire

extension Request {

  public func responseDecodePromise<T>(queue: dispatch_queue_t!, decoder: AnyObject -> T?) -> Promise<T, AlamofirePromiseError> {

    return self.responseJSONPromise(queue)
      .flatMap { json in
        if let value = decoder(json) {
          return Promise(value: value)
        }
        else {
          return Promise(error: AlamofirePromiseError.JsonDecodeError)
        }
    }
  }

  public func responseJSONPromise(queue: dispatch_queue_t!) -> Promise<AnyObject, AlamofirePromiseError> {
    let source = PromiseSource<AnyObject, AlamofirePromiseError>()

    self.response(queue: queue, responseSerializer: Request.JSONResponseSerializer(options: .AllowFragments)) { (request, response, result) -> Void in
      if let resp = response {
        if resp.statusCode == 404 {
          source.reject(AlamofirePromiseError.HttpNotFound(result: result))
          return
        }

        if resp.statusCode < 200 || resp.statusCode > 299 {
          source.reject(AlamofirePromiseError.HttpError(status: resp.statusCode, result: result))
          return
        }
      }

      switch result {
      case let .Success(value):
        source.resolve(value)

      case let .Failure(data, error):
        source.reject(AlamofirePromiseError.UnknownError(error: error, data: data))
      }
    }
    
    return source.promise
  }
}
