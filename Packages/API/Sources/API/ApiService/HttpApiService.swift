//
//  HttpApiService.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 12/12/2018.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import CancellationToken
import Foundation
import Promissum

public struct ApiCredentials {
  let key: String

  public init(key: String) {
    self.key = key
  }

  public init(file: URL) {
    guard let plistDict = NSDictionary(contentsOf: file),
      let key = plistDict["key"] as? String
    else {
      fatalError("Could not read file \(file.absoluteString)")
    }

    self.key = key
  }

  var header: (String, String) {
    return ("Ocp-Apim-Subscription-Key", "\(key)")
  }
}

public final class HttpApiService: ApiService {
  private let credentials: ApiCredentials
  private let session = URLSession(configuration: URLSessionConfiguration.default)

  private lazy var jsonDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .iso8601
    return jsonDecoder
  }()

  public init(credentials: ApiCredentials) {
    self.credentials = credentials
  }

  public func stations(cancellationToken: CancellationToken?) -> Promise<StationsResponse, ApiError> {
    let url = URL(string: "https://gateway.apiportal.ns.nl/reisinformatie-api/api/v2/stations")!

    var request = URLRequest(url: url)
    request.set(credentials: credentials)

    let promiseSource = PromiseSource<StationsResponse, ApiError>()

    let task = session.dataTask(with: request) { [jsonDecoder] data, response, error in
      if let error = error {
        return promiseSource.reject(.external(error: error))
      }

      guard let data = data else {
        return promiseSource.reject(.noData)
      }

      do {
        let response = try jsonDecoder.decode(StationsResponse.self, from: data)
        promiseSource.resolve(response)
      } catch {
        promiseSource.reject(.external(error: error))
      }
    }

    task.resume()

    cancellationToken?.register {
      task.cancel()
    }

    return promiseSource.promise
  }

  public func advices(for adviceRequest: AdviceRequest, scrollRequestForwardContext: String?, cancellationToken: CancellationToken?) -> Promise<AdvicesResponse, ApiError> {
    guard let fromCode = adviceRequest.from?.rawValue,
      let toCode = adviceRequest.to?.rawValue
    else {
      return Promise(error: .noFullRequest)
    }
    // https://ns-api.nl/virtualtrain/v1/trein/3031?features=zitplaats,drukte

    var components = URLComponents()
    components.scheme = "https"
    components.host = "gateway.apiportal.ns.nl"
    components.path = "/reisinformatie-api/api/v3/trips"
    components.queryItems = [
      URLQueryItem(name: "originUicCode", value: fromCode),
      URLQueryItem(name: "destinationUicCode", value: toCode),
      URLQueryItem(name: "excludeHighSpeedTrains", value: "true"),
      URLQueryItem(name: "context", value: scrollRequestForwardContext),
    ]

    let url = components.url!
    var request = URLRequest(url: url)
    request.set(credentials: credentials)

    let promiseSource = PromiseSource<AdvicesResponse, ApiError>()

    let task = session.dataTask(with: request) { [jsonDecoder] data, response, error in
      if let error = error {
        return promiseSource.reject(.external(error: error))
      }

      guard let data = data else {
        return promiseSource.reject(.noData)
      }

      do {
        let response = try jsonDecoder.decode(AdvicesResponse.self, from: data)
        promiseSource.resolve(response)
      } catch {
        print("Catched error \(error)")
        promiseSource.reject(.external(error: error))
      }
    }

    task.resume()

    cancellationToken?.register {
      task.cancel()
    }

    return promiseSource.promise
  }
}

extension URLRequest {
  mutating func set(credentials: ApiCredentials) {
    let header = credentials.header
    setValue(header.1, forHTTPHeaderField: header.0)
  }
}
