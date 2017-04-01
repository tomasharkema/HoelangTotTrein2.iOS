//
//  JsonHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 21-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

// Convert from NSData to json object
public func nsdataToJSON(_ data: Data) -> AnyObject? {
  return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
}

// Convert from JSON to nsdata
public func jsonToNSData(_ json: AnyObject) -> Data?{
  return try? JSONSerialization.data(withJSONObject: json, options: [])
}
