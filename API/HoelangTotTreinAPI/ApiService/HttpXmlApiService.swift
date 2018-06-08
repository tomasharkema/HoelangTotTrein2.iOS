//
//  HttpXmlApiService.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 17-09-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import SWXMLHash

public struct Credentials {
  let username: String
  let password: String

  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }

  public init(file: URL) {
    guard let plistDict = NSDictionary(contentsOf: file),
      let username = plistDict["username"] as? String,
      let password = plistDict["password"] as? String
      else {
        fatalError("Could not read file \(file.absoluteString)")
      }

    self.username = username
    self.password = password
  }

  var header: (String, String) {
    let base64 = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""
    return ("Authorization", "Basic: \(base64)")
  }
}

final public class HttpXmlApiService: ApiService {

  private let credentials: Credentials
  private let xmlParser: SWXMLHash
  private let root: URL
  private let parseQueue = DispatchQueue(label: "HttpXmlApiService", attributes: .concurrent)

  private let session = URLSession(configuration: URLSessionConfiguration.default)
  
  public init(
    credentials: Credentials,
    root: URL = URL(string: "https://webservices.ns.nl/")!)
  {
    self.credentials = credentials
    self.root = root
    xmlParser = SWXMLHash.config { config in
      config.encoding = .utf8
      config.shouldProcessLazily = true
    }
  }
  
  private func xmlResponse(data: Data) -> XMLIndexer {
    return xmlParser.parse(data)
  }

  public func stations() -> Promise<StationsResponse, ApiError> {
    let url = root.appendingPathComponent("ns-api-stations-v2")
    var request = URLRequest(url: url)
    request.set(credentials: credentials)
    
    let promiseSource = PromiseSource<StationsResponse, ApiError>()
    
    let task = session.dataTask(with: request) { (data, response, error) in
      if let error = error {
        return promiseSource.reject(.external(error: error))
      }
      
      guard let data = data else {
        return promiseSource.reject(.noData)
      }
      
      let xml = self.xmlResponse(data: data)
      let response = StationsResponse(stations: xml["Stations"].children.compactMap { stationXml in
        Station(fromXml: stationXml)
      })
      
      promiseSource.resolve(response)
    }
    
    task.resume()
    
    return promiseSource.promise
  }

  public func advices(for adviceRequest: AdviceRequest) -> Promise<AdvicesResult, ApiError> {
    guard let fromCode = adviceRequest.from?.code,
      let toCode = adviceRequest.to?.code
      else {
        return Promise(error: .noFullRequest)
      }

    guard var components = URLComponents(url: root.appendingPathComponent("ns-api-treinplanner"), resolvingAgainstBaseURL: true) else {
      return Promise(error: .noFullRequest)
    }
    components.queryItems = [
      URLQueryItem(name: "fromStation", value: fromCode),
      URLQueryItem(name: "toStation", value: toCode)
    ]
    
    guard let url = components.url else {
      return Promise(error: .noFullRequest)
    }
    
    var request = URLRequest(url: url)
    request.set(credentials: credentials)
    
    let promiseSource = PromiseSource<AdvicesResult, ApiError>()
    
    let task = session.dataTask(with: request) { (data, response, error) in
      if let error = error {
        return promiseSource.reject(.external(error: error))
      }
      
      guard let data = data else {
        return promiseSource.reject(.noData)
      }
      
      let xml = self.xmlResponse(data: data)
      let response = AdvicesResult(advices: xml["ReisMogelijkheden"].children.compactMap { mogelijkheden in
        Advice(fromXml: mogelijkheden, request: AdviceRequestCodes(from: fromCode, to: toCode))
      })
      
      promiseSource.resolve(response)
    }
    
    task.resume()
    
    return promiseSource.promise
  }

  public func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, ApiError> {
    return Promise(error: .notImplemented)
  }

  public func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, ApiError> {
    return Promise(error: .notImplemented)
  }
}

extension Station {
  init?(fromXml: XMLIndexer) {
    guard let name = fromXml["Namen"]["Lang"].element?.text else {
      print("NO NAME")
      return nil
    }

    self.name = name

    guard let code = fromXml["Code"].element?.text else {
      print("NO CODE")
      return nil
    }

    self.code = code

    guard let land = fromXml["Land"].element?.text else {
      print("NO LAND")
      return nil
    }

    self.land = land

    guard let lat = (fromXml["Lat"].element?.text).flatMap({ Double($0) }),
      let lon = (fromXml["Lon"].element?.text).flatMap({ Double($0) }) else {
      print("NO COORD")
      return nil
    }

    self.coords = Coords(lat: lat, lon: lon)

    guard let type = (fromXml["Type"].element?.text).flatMap({ StationType(rawValue: $0) }) else {
      print("NO TYPE")
      return nil
    }

    self.type = type
  }
}

extension URLRequest {
  mutating func set(credentials: Credentials) {
    let header = credentials.header
    setValue(header.1, forHTTPHeaderField: header.0)
  }
}
