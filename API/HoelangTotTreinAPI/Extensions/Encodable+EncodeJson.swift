//
//  Encodable+EncodeJson.swift
//  HoelangTotTreinAPI
//
//  Created by Tomas Harkema on 08-06-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

extension Encodable {
  public func encodeJson() throws -> Any {
    let jsonEncoder = JSONEncoder()
    return try JSONSerialization.jsonObject(with: try jsonEncoder.encode(self), options: [])
  }
}

extension Decodable {
  public static func decodeJson(data: Any) throws -> Self {
    let jsonDecoder = JSONDecoder()
    return try jsonDecoder.decode(Self.self, from: try JSONSerialization.data(withJSONObject: data, options: []))
  }
}
