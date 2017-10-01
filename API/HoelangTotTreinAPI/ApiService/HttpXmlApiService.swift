//
//  HttpXmlApiService.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 17-09-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import Alamofire
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

  var header: [String: String] {
    let base64 = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""
    return ["Authorization": "Basic: \(base64)"]
  }
}

final public class HttpXmlApiService: ApiService {

  private let credentials: Credentials
  private let xmlParser: SWXMLHash
  private let root: URL
  private let parseQueue = DispatchQueue(label: "HttpXmlApiService", attributes: .concurrent)

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

  public func stations() -> Promise<StationsResponse, Error> {
    let url = root.appendingPathComponent("ns-api-stations-v2")

    let request = Alamofire.request(url, headers: credentials.header)
      .validate()

    print(request.debugDescription)

    return request
      .xmlPromise(xmlParser: xmlParser)
      .map { (response: XMLIndexer) in
        StationsResponse(stations: response["Stations"].children.flatMap { stationXml in
          Station(fromXml: stationXml)
        })
      }
  }

  public func advices(for adviceRequest: AdviceRequest) -> Promise<AdvicesResult, Error> {
    guard let fromCode = adviceRequest.from?.code,
      let toCode = adviceRequest.to?.code
      else {
        return Promise(error: ApiError.noFullRequest)
      }

    let url = root.appendingPathComponent("ns-api-treinplanner")
    let parameters = [
      "fromStation": fromCode,
      "toStation": toCode
    ]

    let request = Alamofire.request(url, parameters: parameters, headers: credentials.header)
      .validate()

    print(request.debugDescription)

    return request
      .validate()
      .xmlPromise(xmlParser: xmlParser)
      .map { result in
        AdvicesResult(advices: result["ReisMogelijkheden"].children.flatMap { mogelijkheden in
          Advice(fromXml: mogelijkheden, request: AdviceRequestCodes(from: fromCode, to: toCode))
        })
      }
  }

  public func registerForNotification(_ userId: String, from: Station, to: Station) -> Promise<SuccessResult, Error> {
    return Promise(error: ApiError.notImplemented)
  }

  public func registerForNotification(_ userId: String, env: String, pushUUID: String) -> Promise<SuccessResult, Error> {
    return Promise(error: ApiError.notImplemented)
  }
}

extension DataRequest {
  func xmlPromise(xmlParser: SWXMLHash = SWXMLHash.config({ $0 })) -> Promise<XMLIndexer, Error> {
    return responseStringPromise()
      .mapError()
      .map { result in xmlParser.parse(result.result) }
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
