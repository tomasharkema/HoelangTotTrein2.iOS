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

private struct Keys {
  static let FromStationCodeKey = "FromStationCodeKey"
  static let ToStationCodeKey = "ToStationCodeKey"
  static let FromStationByPickerCodeKey = "FromStationByPickerCodeKey"
  static let ToStationByPickerCodeKey = "ToStationByPickerCodeKey"
  static let UserIdKey = "UserIdKey"
  static let GeofenceInfoKey = "GeofenceInfoKey"
  static let PersistedAdvicesAndRequest = "PersistedAdvicesAndRequest"
  static let CurrentAdviceIdentifier = "CurrentAdviceIdentifier"
  static let PersistedAdvices = "PersistedAdvices"
  static let KeepDepartedAdvice = "KeepDepartedAdvice"
  static let FirstLegRitNummers = "FirstLegRitNummers"
}

private let UserDefaults = Foundation.UserDefaults(suiteName: "group.tomas.hltt")!

extension AppDataStore {

  public var fromStationCode: String? {
    get {
      let fromCode = UserDefaults.string(forKey: Keys.FromStationCodeKey)
      return fromCode
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.FromStationCodeKey)
      UserDefaults.synchronize()
    }
  }

  public var toStationCode: String? {
    get {
      let toCode = UserDefaults.string(forKey: Keys.ToStationCodeKey)
      return toCode
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.ToStationCodeKey)
      UserDefaults.synchronize()
    }
  }

  public var fromStationByPickerCode: String? {
    get {
      let fromCode = UserDefaults.string(forKey: Keys.FromStationByPickerCodeKey)
      return fromCode
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.FromStationByPickerCodeKey)
      UserDefaults.synchronize()
    }
  }

  public var toStationByPickerCode: String? {
    get {
      let toCode = UserDefaults.string(forKey: Keys.ToStationByPickerCodeKey)
      return toCode
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.ToStationByPickerCodeKey)
      UserDefaults.synchronize()
    }
  }

  public var userId: String {
    let returnedUserId: String
    if let userId = UserDefaults.string(forKey: Keys.UserIdKey) {
      returnedUserId = userId
    } else {
      returnedUserId = UUID().uuidString
      UserDefaults.set(returnedUserId, forKey: Keys.UserIdKey)
      UserDefaults.synchronize()
    }
    return returnedUserId
  }

  public var geofenceInfo: [String: [GeofenceModel]]? {
    set {
      let encoder = JSONEncoder()
      do {
        UserDefaults.set(try encoder.encode(newValue), forKey: Keys.GeofenceInfoKey)
      } catch {
        fatalError("Error! \(error)")
      }
    }
    get {
      let decoder = JSONDecoder()
      guard let data = UserDefaults.data(forKey: Keys.GeofenceInfoKey) else {
        return nil
      }
      do {
        return try decoder.decode([String: [GeofenceModel]].self, from: data)
      } catch {
        fatalError("Error! \(error)")
      }
    }
  }

  fileprivate var persistedAdvicesAndRequestObject: [String: Any]? {
    get {
      assert(!Thread.isMainThread)
      guard let data = UserDefaults.object(forKey: Keys.PersistedAdvicesAndRequest) as? Data else {
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
      assert(!Thread.isMainThread, "PLEASE DONT CALL FROM MAIN THREAD")
      do {
        guard let value = newValue else {
          return
        }

        let json: Data = try JSONSerialization.data(withJSONObject: value, options: [])
        UserDefaults.set(json, forKey: Keys.PersistedAdvicesAndRequest)
        UserDefaults.synchronize()
      } catch {
        assertionFailure("ERROR: \(error)")
      }
    }
  }

  public var currentAdviceIdentifier: String? {
    get {
      return UserDefaults.string(forKey: Keys.CurrentAdviceIdentifier)
    }

    set {
      UserDefaults.set(newValue ?? 0, forKey: Keys.CurrentAdviceIdentifier)
      UserDefaults.synchronize()
    }
  }

  public var persistedAdvices: Advices? {
    set {
      let encoder = JSONEncoder()
      do {
        UserDefaults.set(try encoder.encode(newValue), forKey: Keys.PersistedAdvices)
      } catch {
        fatalError("Error! \(error)")
      }
    }

    get {
      let decoder = JSONDecoder()
      guard let data = UserDefaults.data(forKey: Keys.PersistedAdvices) else {
        return nil
      }
      do {
        return try decoder.decode(Advices.self, from: data)
      } catch {
        fatalError("Error! \(error)")
      }
    }
  }

  public var keepDepartedAdvice: Bool {
    get {
      return UserDefaults.object(forKey: Keys.KeepDepartedAdvice) as? Bool ?? defaultKeepDepartedAdvice
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.KeepDepartedAdvice)
      UserDefaults.synchronize()
    }
  }
  
  public var firstLegRitNummers: [String] {
    get {
      return UserDefaults.object(forKey: Keys.FirstLegRitNummers) as? [String] ?? []
    }
    set {
      UserDefaults.set(newValue, forKey: Keys.FirstLegRitNummers)
      UserDefaults.synchronize()
    }
  }
}
