//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit

struct Keys {
  static let FromStationCodeKey = "FromStationCodeKey"
  static let ToStationCodeKey = "ToStationCodeKey"
  static let FromStationByPickerCodeKey = "FromStationByPickerCodeKey"
  static let ToStationByPickerCodeKey = "ToStationByPickerCodeKey"
  static let UserIdKey = "UserIdKey"
  static let GeofenceInfoKey = "GeofenceInfoKey"
}

let UserDefaults = NSUserDefaults.standardUserDefaults()

extension NSUserDefaults {
  var fromStationCode: String? {
    get {
      let fromCode = stringForKey(Keys.FromStationCodeKey)
      return fromCode
    }
    set {
      setObject(newValue, forKey: Keys.FromStationCodeKey)
    }
  }

  var toStationCode: String? {
    get {
      let toCode = stringForKey(Keys.ToStationCodeKey)
      return toCode
    }
    set {
      setObject(newValue, forKey: Keys.ToStationCodeKey)
    }
  }

  var fromStationByPickerCode: String? {
    get {
      let fromCode = stringForKey(Keys.FromStationByPickerCodeKey)
      return fromCode
    }
    set {
      setObject(newValue, forKey: Keys.FromStationByPickerCodeKey)
    }
  }

  var toStationByPickerCode: String? {
    get {
      let toCode = stringForKey(Keys.ToStationByPickerCodeKey)
      return toCode
    }
    set {
      setObject(newValue, forKey: Keys.ToStationByPickerCodeKey)
    }
  }

  var userId: String {
    let returnedUserId: String
    if let userId = stringForKey(Keys.UserIdKey) {
      returnedUserId = userId
    } else {
      returnedUserId = NSUUID().UUIDString
      setObject(returnedUserId, forKey: Keys.UserIdKey)
    }
    return returnedUserId
  }


  var geofenceInfo: [String: [GeofenceModel]]? {
    set {
      if let value = newValue {
        let dict = value.encodeJson({$0}) {
          $0.encodeJson {
            $0.encodeJson()
          }
        }

        _geofenceInfo = dict
      }
    }
    get {
      if let dict = _geofenceInfo {
        do {
          return try Dictionary.decodeJson({
            try String.decodeJson($0)
            }, {
              return try Array.decodeJson({
                try GeofenceModel.decodeJson($0)
              }, $0)
            }, dict)
        } catch {
          print(error)
        }
      }
      return nil
    }
  }


  private var _geofenceInfo: [String: AnyObject]? {
    get {
      if let data = objectForKey(Keys.GeofenceInfoKey) as? NSData, object = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
        return object as? [String: AnyObject]
      }
      return nil
    }
    set {
      if let value = newValue, json = try? NSJSONSerialization.dataWithJSONObject(value, options: []) {
        setObject(json, forKey: Keys.GeofenceInfoKey)
      }
    }
  }
}
