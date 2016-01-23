//
//  JsonGen+Alamofire.swift
//  PostNL
//
//  Created by Tom Lokhorst on 04/11/15.
//  Copyright © 2015 PostNL. All rights reserved.
//

import Alamofire
import Promissum

// Note: This type will be extended to more types of decode errors in a newer version of JsonGen
public enum JsonDecodeResponseSerializerError : ErrorType {
  case DecodeError(JsonDecodeError)
  case OtherError(NSError)
}

extension Request {

  public static func JsonDecodeResponseSerializer<T>(
    decoder decoder: AnyObject throws -> T)
    -> ResponseSerializer<T, JsonDecodeResponseSerializerError>
  {
    let jsonSerializer = Request.JSONResponseSerializer().serializeResponse

    return ResponseSerializer { request, response, data, error in
      let jsonResult = jsonSerializer(request, response, data, error)

      switch jsonResult {
      case .Success(let object):
        do {
          let value = try decoder(object)
          return .Success(value)
        }
        catch let error as JsonDecodeError {
          #if DEBUG
            assertionFailure("JsonDecodeError: \(error.fullDescription)")
          #endif

          let jsonDecodeResponseSerializerError = JsonDecodeResponseSerializerError.DecodeError(error)
          return .Failure(jsonDecodeResponseSerializerError)
        }
        catch {
          let nsError = error as NSError
          let jsonDecodeResponseSerializerError = JsonDecodeResponseSerializerError.OtherError(nsError)
          return .Failure(jsonDecodeResponseSerializerError)
        }
      case .Failure(let error):
        let jsonDecodeResponseSerializerError = JsonDecodeResponseSerializerError.OtherError(error)
        return .Failure(jsonDecodeResponseSerializerError)
      }
    }
  }

  public func responseJsonDecode<T>(
    decoder decoder: AnyObject throws -> T,
    completionHandler: Response<T, JsonDecodeResponseSerializerError> -> Void)
    -> Self
  {
    return response(
      responseSerializer: Request.JsonDecodeResponseSerializer(decoder: decoder),
      completionHandler: completionHandler
    )
  }

  public func responseJsonDecodePromise<T>(
    decoder decoder: AnyObject throws -> T)
    -> Promise<SuccessResponse<T>, ErrorResponse<JsonDecodeResponseSerializerError>>
  {
    return self.responsePromise(responseSerializer: Request.JsonDecodeResponseSerializer(decoder: decoder))
  }
}

extension ErrorResponse {

  func decode<T>(statusCode statusCode: Int, decoder: AnyObject throws -> T) -> T? {
    if self.response?.statusCode == statusCode {
      if let data = self.data,
        let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
        let decoded = try? decoder(json)
      {
        return decoded
      }
    }

    return nil
  }
}
