//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Bindable

#if canImport(HoelangTotTreinAPIWatch)
import HoelangTotTreinAPIWatch
#endif
#if canImport(HoelangTotTreinAPI)
import HoelangTotTreinAPI
#endif

private struct Keys {
  static let fromStationCodeKey = "FromStationCodeKey"
  static let toStationCodeKey = "ToStationCodeKey"
  static let fromStationByPickerCodeKey = "FromStationByPickerCodeKey"
  static let toStationByPickerCodeKey = "ToStationByPickerCodeKey"
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
  var fromStationByPickerCode: Variable<String?> { get }
  var toStationByPickerCode: Variable<String?> { get }
  func setFromStationByPickerCode(code: String?)
  func setToStationByPickerCode(code: String?)

  var currentAdviceIdentifier: Variable<AdviceIdentifier?> { get }
  func setCurrentAdviceIdentifier(identifier: AdviceIdentifier?)

  var userId: String { get }
  var geofenceInfo: [String: [GeofenceModel]]? { get set }
  var persistedAdvicesAndRequest: AdvicesAndRequest? { get set }
  var keepDepartedAdvice: Bool { get set }
  var firstLegRitNummers: [String] { get set }
  var appSettings: AppSettings { get set }
}

public class UserDefaultsPreferenceStore: PreferenceStore {

  public let fromStationByPickerCode: Variable<String?>
  public let toStationByPickerCode: Variable<String?>

  private let fromStationByPickerCodeSource = VariableSource<String?>(value: nil)
  private let toStationByPickerCodeSource = VariableSource<String?>(value: nil)

  private let currentAdviceIdentifierSource = VariableSource<AdviceIdentifier?>(value: nil)
  public let currentAdviceIdentifier: Variable<AdviceIdentifier?>

  private let defaultKeepDepartedAdvice: Bool

  public init(defaultKeepDepartedAdvice: Bool) {
    self.defaultKeepDepartedAdvice = defaultKeepDepartedAdvice
    
    fromStationByPickerCode = fromStationByPickerCodeSource.variable
    toStationByPickerCode = toStationByPickerCodeSource.variable

    currentAdviceIdentifier = currentAdviceIdentifierSource.variable

    prefill()
  }

  private func prefill() {
    currentAdviceIdentifierSource.value = currentAdviceIdentifierValue
    fromStationByPickerCodeSource.value = fromStationByPickerCodeDefaults
    toStationByPickerCodeSource.value = toStationByPickerCodeDefaults
  }

  public func setFromStationByPickerCode(code: String?) {
    fromStationByPickerCodeDefaults = code
    fromStationByPickerCodeSource.value = code
  }

  public func setToStationByPickerCode(code: String?) {
    toStationByPickerCodeDefaults = code
    toStationByPickerCodeSource.value = code
  }

  private var fromStationCodeDefaults: String? {
    get {
      let fromCode = HLTTUserDefaults.string(forKey: Keys.fromStationCodeKey)
      return fromCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.fromStationCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var toStationCodeDefaults: String? {
    get {
      let toCode = HLTTUserDefaults.string(forKey: Keys.toStationCodeKey)
      return toCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.toStationCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var fromStationByPickerCodeDefaults: String? {
    get {
      let fromCode = HLTTUserDefaults.string(forKey: Keys.fromStationByPickerCodeKey)
      return fromCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.fromStationByPickerCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var toStationByPickerCodeDefaults: String? {
    get {
      let toCode = HLTTUserDefaults.string(forKey: Keys.toStationByPickerCodeKey)
      return toCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.toStationByPickerCodeKey)
      HLTTUserDefaults.synchronize()
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

  public var persistedAdvicesAndRequest: AdvicesAndRequest? {
    set {
      do {
        let data = try JSONEncoder().encode(newValue)
        HLTTUserDefaults.set(data, forKey: Keys.persistedAdvicesAndRequest)
      } catch {
        print(error)
        HLTTUserDefaults.set(nil, forKey: Keys.persistedAdvicesAndRequest)
      }
    }
    get {
      do {
        guard let data = HLTTUserDefaults.data(forKey: Keys.persistedAdvicesAndRequest) else {
          return nil
        }
        let object = try JSONDecoder().decode(AdvicesAndRequest.self, from: data)
        return object
      } catch {
        print(error)
        return nil
      }
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
