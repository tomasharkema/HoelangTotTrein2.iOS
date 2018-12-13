//
//  HttpApiService.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 12/12/2018.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import CancellationToken

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
    return ("x-api-key", "\(key)")
  }
}

final public class HttpApiService: ApiService {
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
    let url = URL(string: "https://ns-api.nl/reisinfo/api/v2/stations")!
    
    var request = URLRequest(url: url)
    request.set(credentials: credentials)
    
    let promiseSource = PromiseSource<StationsResponse, ApiError>()
    
    let task = session.dataTask(with: request) { [jsonDecoder] (data, response, error) in
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
  
  public func advices(for adviceRequest: AdviceRequest, cancellationToken: CancellationToken?) -> Promise<AdvicesResponse, ApiError> {
    guard let fromCode = adviceRequest.from?.code,
      let toCode = adviceRequest.to?.code
      else {
        return Promise(error: .noFullRequest)
      }
    
    let url = URL(string: "https://ns-api.nl/reisinfo/api/v3/trips?fromStation=\(fromCode)&toStation=\(toCode)")!
    var request = URLRequest(url: url)
    request.set(credentials: credentials)
    
    let promiseSource = PromiseSource<AdvicesResponse, ApiError>()
    
    let task = session.dataTask(with: request) { [jsonDecoder] (data, response, error) in
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
