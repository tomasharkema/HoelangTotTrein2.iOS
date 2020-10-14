//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Bindable
import API

private struct Keys {
  static let adviceRequestDefaults = "adviceRequestDefaults"
  static let originalAdviceRequestDefaults = "originalAdviceRequestDefaults"
  static let userIdKey = "UserIdKey"
  static let geofenceInfoKey = "GeofenceInfoKey"
  static let persistedAdvicesAndRequest = "PersistedAdvicesAndRequest"
  static let currentAdviceIdentifier = "CurrentAdviceIdentifier"
  static let keepDepartedAdvice = "KeepDepartedAdvice"
  static let firstLegRitNummers = "FirstLegRitNummers"
  static let appSettings = "AppSettings"
}

private let HLTTUserDefaults = Foundation.UserDefaults(suiteName: "group.tomas.hltt")!

public protocol PreferenceStore: class {
  var adviceRequest: Variable<AdviceRequest> { get }
  func set(adviceRequest: AdviceRequest)
  
  var originalAdviceRequest: Variable<AdviceRequest> { get }
  func set(originalAdviceRequest: AdviceRequest)
  
  var currentAdviceIdentifier: Variable<AdviceIdentifier?> { get }
  func setCurrentAdviceIdentifier(identifier: AdviceIdentifier?)

  var userId: String { get }
  var geofenceInfo: [String: [GeofenceModel]]? { get set }
//  var persistedAdvicesAndRequest: AdvicesAndRequest? { get set }

  func persistedAdvicesAndRequest(for adviceRequest: AdviceRequest) -> AdvicesAndRequest?
  func setPersistedAdvicesAndRequest(for adviceRequest: AdviceRequest, persisted: AdvicesAndRequest?)

  var keepDepartedAdvice: Bool { get set }
  var firstLegRitNummers: [String] { get set }
  var appSettings: AppSettings { get set }
}

public class UserDefaultsPreferenceStore: PreferenceStore {
  
  public var adviceRequestSource = VariableSource<AdviceRequest>(value: AdviceRequest(from: nil, to: nil))
  public var adviceRequest: Variable<AdviceRequest>
  
  public var originalAdviceRequestSource = VariableSource<AdviceRequest>(value: AdviceRequest(from: nil, to: nil))
  public var originalAdviceRequest: Variable<AdviceRequest>

  private let currentAdviceIdentifierSource = VariableSource<AdviceIdentifier?>(value: nil)
  public let currentAdviceIdentifier: Variable<AdviceIdentifier?>

  private let defaultKeepDepartedAdvice: Bool

  public init(defaultKeepDepartedAdvice: Bool) {
    self.defaultKeepDepartedAdvice = defaultKeepDepartedAdvice

    adviceRequest = adviceRequestSource.variable
    originalAdviceRequest = originalAdviceRequestSource.variable
    currentAdviceIdentifier = currentAdviceIdentifierSource.variable

    prefill()
  }

  private func prefill() {
    currentAdviceIdentifierSource.value = currentAdviceIdentifierValue
    
    if let adviceRequestDefaults = adviceRequestDefaults {
      adviceRequestSource.value = adviceRequestDefaults
    }
    if let originalAdviceRequestDefaults = originalAdviceRequestDefaults {
      originalAdviceRequestSource.value = originalAdviceRequestDefaults
    }
  }
  
  public func set(adviceRequest: AdviceRequest) {
    adviceRequestDefaults = adviceRequest
    adviceRequestSource.value = adviceRequest
  }
  
  
  public func set(originalAdviceRequest: AdviceRequest) {
    originalAdviceRequestDefaults = originalAdviceRequest
    originalAdviceRequestSource.value = originalAdviceRequest
  }
  
  private var adviceRequestDefaults: AdviceRequest? {
    get {
      return HLTTUserDefaults.data(forKey: Keys.adviceRequestDefaults)
        .flatMap {
          try? JSONDecoder().decode(AdviceRequest.self, from: $0)
        }
    }
    set {
      let data = newValue.flatMap {
        try? JSONEncoder().encode($0)
      }
      HLTTUserDefaults.set(data, forKey: Keys.adviceRequestDefaults)
    }
  }

  private var originalAdviceRequestDefaults: AdviceRequest? {
    get {
      return HLTTUserDefaults.data(forKey: Keys.originalAdviceRequestDefaults)
        .flatMap {
          try? JSONDecoder().decode(AdviceRequest.self, from: $0)
      }
    }
    set {
      let data = newValue.flatMap {
        try? JSONEncoder().encode($0)
      }
      HLTTUserDefaults.set(data, forKey: Keys.originalAdviceRequestDefaults)
    }
  }
  
  public var userId: String {
    let returnedUserId: String
    if let userId = HLTTUserDefaults.string(forKey: Keys.userIdKey) {
      returnedUserId = userId
    } else {
      returnedUserId = UUID().uuidString
      HLTTUserDefaults.set(returnedUserId, forKey: Keys.userIdKey)
      HLTTUserDefaults.synchronize()
    }
    return returnedUserId
  }

  public var geofenceInfo: [String: [GeofenceModel]]? {
    set {
      let encoder = JSONEncoder()
      do {
        HLTTUserDefaults.set(try encoder.encode(newValue), forKey: Keys.geofenceInfoKey)
      } catch {
        assertionFailure("Error! \(error)")
      }
    }
    get {
      let decoder = JSONDecoder()
      guard let data = HLTTUserDefaults.data(forKey: Keys.geofenceInfoKey) else {
        return nil
      }

      return try? decoder.decode([String: [GeofenceModel]].self, from: data)
    }
  }

  fileprivate var persistedAdvicesAndRequestObject: [String: Any]? {
    get {
      guard let data = HLTTUserDefaults.object(forKey: Keys.persistedAdvicesAndRequest) as? Data else {
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
      do {
        guard let value = newValue else {
          return
        }

        let json: Data = try JSONSerialization.data(withJSONObject: value, options: [])
        HLTTUserDefaults.set(json, forKey: Keys.persistedAdvicesAndRequest)
        HLTTUserDefaults.synchronize()
      } catch {
        assertionFailure("ERROR: \(error)")
      }
    }
  }

  public func setCurrentAdviceIdentifier(identifier: AdviceIdentifier?) {
    currentAdviceIdentifierValue = identifier
    currentAdviceIdentifierSource.value = identifier
  }
  private var currentAdviceIdentifierValue: AdviceIdentifier? {
    get {
      return HLTTUserDefaults.string(forKey: Keys.currentAdviceIdentifier).map {
        AdviceIdentifier(rawValue: $0)
      }
    }

    set {
      HLTTUserDefaults.set(newValue?.rawValue ?? 0, forKey: Keys.currentAdviceIdentifier)
      HLTTUserDefaults.synchronize()
    }
  }

  public var keepDepartedAdvice: Bool {
    get {
      return HLTTUserDefaults.object(forKey: Keys.keepDepartedAdvice) as? Bool ?? defaultKeepDepartedAdvice
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.keepDepartedAdvice)
      HLTTUserDefaults.synchronize()
    }
  }
  
  public var firstLegRitNummers: [String] {
    get {
      return HLTTUserDefaults.object(forKey: Keys.firstLegRitNummers) as? [String] ?? []
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.firstLegRitNummers)
      HLTTUserDefaults.synchronize()
    }
  }

  public func persistedAdvicesAndRequest(for adviceRequest: AdviceRequest) -> AdvicesAndRequest? {
    do {
      guard let data = HLTTUserDefaults.data(forKey: "\(Keys.persistedAdvicesAndRequest):\(adviceRequest)") else {
        return nil
      }
      let object = try JSONDecoder().decode(AdvicesAndRequest.self, from: data)
      return object
    } catch {
      print(error)
      return nil
    }
  }

  public func setPersistedAdvicesAndRequest(for adviceRequest: AdviceRequest, persisted: AdvicesAndRequest?) {
    do {
      let data = try JSONEncoder().encode(persisted)
      HLTTUserDefaults.set(data, forKey: "\(Keys.persistedAdvicesAndRequest):\(adviceRequest)")
    } catch {
      print(error)
      HLTTUserDefaults.set(nil, forKey: "\(Keys.persistedAdvicesAndRequest):\(adviceRequest)")
    }
  }

  public var appSettings: AppSettings {
    get {
      return AppSettings(rawValue: HLTTUserDefaults.integer(forKey: Keys.appSettings))
    }
    set {
      HLTTUserDefaults.set(newValue.rawValue, forKey: Keys.appSettings)
    }
  }
}

// MARK: - Settings

public struct AppSettings: OptionSet {
  public let rawValue: Int

  public static let transferNotificationEnabled = AppSettings(rawValue: 1 << 0)

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}
