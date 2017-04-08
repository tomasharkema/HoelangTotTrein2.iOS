//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import UIKit
import Statham

#if os(watchOS)
  import HoelangTotTreinAPIWatch
#elseif os(iOS)
  import HoelangTotTreinAPI
#endif

struct Keys {
  static let FromStationCodeKey = "FromStationCodeKey"
  static let ToStationCodeKey = "ToStationCodeKey"
  static let FromStationByPickerCodeKey = "FromStationByPickerCodeKey"
  static let ToStationByPickerCodeKey = "ToStationByPickerCodeKey"
  static let UserIdKey = "UserIdKey"
  static let GeofenceInfoKey = "GeofenceInfoKey"
  static let PersistedAdvicesAndRequest = "PersistedAdvicesAndRequest"
  static let CurrentAdviceHash = "CurrentAdviceHash"
  static let PersistedAdvices = "PersistedAdvices"
}

let UserDefaults = Foundation.UserDefaults(suiteName: "group.tomas.hltt")!

extension Foundation.UserDefaults {
  var fromStationCode: String? {
    get {
      let fromCode = string(forKey: Keys.FromStationCodeKey)
      return fromCode
    }
    set {
      set(newValue, forKey: Keys.FromStationCodeKey)
      synchronize()
    }
  }

  var toStationCode: String? {
    get {
      let toCode = string(forKey: Keys.ToStationCodeKey)
      return toCode
    }
    set {
      set(newValue, forKey: Keys.ToStationCodeKey)
      synchronize()
    }
  }

  var fromStationByPickerCode: String? {
    get {
      let fromCode = string(forKey: Keys.FromStationByPickerCodeKey)
      return fromCode
    }
    set {
      set(newValue, forKey: Keys.FromStationByPickerCodeKey)
      synchronize()
    }
  }

  var toStationByPickerCode: String? {
    get {
      let toCode = string(forKey: Keys.ToStationByPickerCodeKey)
      return toCode
    }
    set {
      set(newValue, forKey: Keys.ToStationByPickerCodeKey)
      synchronize()
    }
  }

  var userId: String {
    let returnedUserId: String
    if let userId = string(forKey: Keys.UserIdKey) {
      returnedUserId = userId
    } else {
      returnedUserId = UUID().uuidString
      set(returnedUserId, forKey: Keys.UserIdKey)
      synchronize()
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

        geofenceInfoObject = dict
      }
    }
    get {
      if let dict = geofenceInfoObject {
        do {
          return try Dictionary.decodeJson({
            try String.decodeJson($0)
            }, {
              return try Array.decodeJson({
                try GeofenceModel.decodeJson($0)
              })($0)
            })(dict)
        } catch {
          print(error)
        }
      }
      return nil
    }
  }


  fileprivate var geofenceInfoObject: [String: Any]? {
    get {
      assert(!Thread.isMainThread)
      guard let data = object(forKey: Keys.GeofenceInfoKey) as? Data else {
        return nil
      }

      do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        return object as? [String: Any]
      } catch {
        assertionFailure("ERROR: \(error)")
        return nil
      }
    }
    set {
      assert(!Thread.isMainThread)
      if let value = newValue, let json = try? JSONSerialization.data(withJSONObject: value, options: []) {
        set(json, forKey: Keys.GeofenceInfoKey)
        synchronize()
      }
    }
  }

  var persistedAdvicesAndRequest: AdvicesAndRequest? {
    set {
      if let value = newValue {

        let dict = value.encodeJson()

        persistedAdvicesAndRequestObject = dict
      }
    }
    get {
      if let dict = persistedAdvicesAndRequestObject {
        do {
          return try AdvicesAndRequest.decodeJson(dict)
        } catch {
          print(error)
        }
      }
      return nil
    }
  }

  fileprivate var persistedAdvicesAndRequestObject: [String: Any]? {
    get {
      assert(!Thread.isMainThread)
      guard let data = object(forKey: Keys.PersistedAdvicesAndRequest) as? Data else {
        return nil
      }

      do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        return object as? [String: Any]
      } catch {
        assertionFailure("ERROR: \(error)")
        return nil
      }
    }
    set {
      assert(!Thread.isMainThread)
      do {
        guard let value = newValue else {
          return
        }

        let json: Data = try JSONSerialization.data(withJSONObject: value, options: [])
        set(json, forKey: Keys.PersistedAdvicesAndRequest)
        synchronize()
      } catch {
        assertionFailure("ERROR: \(error)")
      }
    }
  }

  var currentAdviceHash: Int? {
    get {
      let value = integer(forKey: Keys.CurrentAdviceHash)
      return value == 0 ? nil : value
    }

    set {
      set(newValue ?? 0, forKey: Keys.CurrentAdviceHash)
      synchronize()
    }
  }

  var persistedAdvices: Advices? {
    set {
      if let value = newValue {
        let array = value.encodeJson {
          $0.encodeJson()
        }
        persistedAdvicesObject = array
      }
    }
    get {
      if let array = persistedAdvicesObject {
        do {
          return try Array.decodeJson({
            try Advice.decodeJson($0)
          })(array)
        } catch {
          print(error)
        }
      }
      return nil
    }
  }

  fileprivate var persistedAdvicesObject: [Any]? {
    get {
      assert(!Thread.isMainThread)
      guard let data = object(forKey: Keys.PersistedAdvices) as? Data else {
        return nil
      }

      do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        return object as? [Any]
      } catch {
        assertionFailure("ERROR: \(error)")
        return nil
      }
    }
    set {
      assert(!Thread.isMainThread)
      if let value = newValue, let json = try? JSONSerialization.data(withJSONObject: value, options: []) {
        set(json, forKey: Keys.PersistedAdvices)
        synchronize()
      }
    }
  }
}
