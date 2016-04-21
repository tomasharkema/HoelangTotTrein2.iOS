//
//  JsonHelpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 21-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

// Convert from NSData to json object
public func nsdataToJSON(data: NSData) -> AnyObject? {
  return try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
}

// Convert from JSON to nsdata
public func jsonToNSData(json: AnyObject) -> NSData?{
  return try? NSJSONSerialization.dataWithJSONObject(json, options: [])
}
