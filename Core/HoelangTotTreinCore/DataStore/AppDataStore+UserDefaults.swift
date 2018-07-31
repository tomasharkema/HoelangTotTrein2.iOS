//
//  NSUserDefaults+HLTT.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Bindable

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
  static let AppSettings = "AppSettings"
}

private let HLTTUserDefaults = Foundation.UserDefaults(suiteName: "group.tomas.hltt")!

public protocol PreferenceStore: class {
  var fromStationCode: Variable<String?> { get }
  var toStationCode: Variable<String?> { get }
  func setFromStationCode(code: String?)
  func setToStationCode(code: String?)

  var fromStationByPickerCode: Variable<String?> { get }
  var toStationByPickerCode: Variable<String?> { get }
  func setFromStationByPickerCode(code: String?)
  func setToStationByPickerCode(code: String?)

  var userId: String { get }
  var geofenceInfo: [String: [GeofenceModel]]? { get set }
  var persistedAdvicesAndRequest: AdvicesAndRequest? { get set }
  var currentAdviceIdentifier: String? { get set }
  var persistedAdvices: Advices? { get set }
  var keepDepartedAdvice: Bool { get set }
  var firstLegRitNummers: [String] { get set }
  var appSettings: AppSettings { get set }
}

public class UserDefaultsPreferenceStore: PreferenceStore {

  public var fromStationCode: Variable<String?>
  public var toStationCode: Variable<String?>
  public var fromStationByPickerCode: Variable<String?>
  public var toStationByPickerCode: Variable<String?>

  public var fromStationCodeSource = VariableSource<String?>(value: nil)
  public var toStationCodeSource = VariableSource<String?>(value: nil)
  public var fromStationByPickerCodeSource = VariableSource<String?>(value: nil)
  public var toStationByPickerCodeSource = VariableSource<String?>(value: nil)

  private let defaultKeepDepartedAdvice: Bool

  public init(defaultKeepDepartedAdvice: Bool) {
    self.defaultKeepDepartedAdvice = defaultKeepDepartedAdvice
    
    fromStationCode = fromStationCodeSource.variable
    toStationCode = toStationCodeSource.variable
    fromStationByPickerCode = fromStationByPickerCodeSource.variable
    toStationByPickerCode = toStationByPickerCodeSource.variable

    prefill()
  }

  private func prefill() {
    fromStationCodeSource.value = fromStationCodeDefaults
    toStationCodeSource.value = toStationCodeDefaults
    fromStationByPickerCodeSource.value = fromStationByPickerCodeDefaults
    toStationByPickerCodeSource.value = toStationByPickerCodeDefaults
  }

  public func setFromStationCode(code: String?) {
    fromStationCodeDefaults = code
    fromStationCodeSource.value = code
  }

  public func setToStationCode(code: String?) {
    toStationCodeDefaults = code
    toStationCodeSource.value = code
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
      let fromCode = HLTTUserDefaults.string(forKey: Keys.FromStationCodeKey)
      return fromCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.FromStationCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var toStationCodeDefaults: String? {
    get {
      let toCode = HLTTUserDefaults.string(forKey: Keys.ToStationCodeKey)
      return toCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.ToStationCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var fromStationByPickerCodeDefaults: String? {
    get {
      let fromCode = HLTTUserDefaults.string(forKey: Keys.FromStationByPickerCodeKey)
      return fromCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.FromStationByPickerCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }

  private var toStationByPickerCodeDefaults: String? {
    get {
      let toCode = HLTTUserDefaults.string(forKey: Keys.ToStationByPickerCodeKey)
      return toCode
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.ToStationByPickerCodeKey)
      HLTTUserDefaults.synchronize()
    }
  }


  public var userId: String {
    let returnedUserId: String
    if let userId = HLTTUserDefaults.string(forKey: Keys.UserIdKey) {
      returnedUserId = userId
    } else {
      returnedUserId = UUID().uuidString
      HLTTUserDefaults.set(returnedUserId, forKey: Keys.UserIdKey)
      HLTTUserDefaults.synchronize()
    }
    return returnedUserId
  }

  public var geofenceInfo: [String: [GeofenceModel]]? {
    set {
      let encoder = JSONEncoder()
      do {
        HLTTUserDefaults.set(try encoder.encode(newValue), forKey: Keys.GeofenceInfoKey)
      } catch {
        assertionFailure("Error! \(error)")
      }
    }
    get {
      let decoder = JSONDecoder()
      guard let data = HLTTUserDefaults.data(forKey: Keys.GeofenceInfoKey) else {
        return nil
      }

      return try? decoder.decode([String: [GeofenceModel]].self, from: data)
    }
  }

  fileprivate var persistedAdvicesAndRequestObject: [String: Any]? {
    get {
      guard let data = HLTTUserDefaults.object(forKey: Keys.PersistedAdvicesAndRequest) as? Data else {
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
        HLTTUserDefaults.set(json, forKey: Keys.PersistedAdvicesAndRequest)
        HLTTUserDefaults.synchronize()
      } catch {
        assertionFailure("ERROR: \(error)")
      }
    }
  }

  public var currentAdviceIdentifier: String? {
    get {
      return HLTTUserDefaults.string(forKey: Keys.CurrentAdviceIdentifier)
    }

    set {
      HLTTUserDefaults.set(newValue ?? 0, forKey: Keys.CurrentAdviceIdentifier)
      HLTTUserDefaults.synchronize()
    }
  }

  public var persistedAdvices: Advices? {
    set {
      let encoder = JSONEncoder()
      do {
        HLTTUserDefaults.set(try encoder.encode(newValue), forKey: Keys.PersistedAdvices)
      } catch {
        assertionFailure("Error! \(error)")
      }
    }

    get {
      let decoder = JSONDecoder()
      guard let data = HLTTUserDefaults.data(forKey: Keys.PersistedAdvices) else {
        return nil
      }

      return try? decoder.decode(Advices.self, from: data)
    }
  }

  public var keepDepartedAdvice: Bool {
    get {
      return HLTTUserDefaults.object(forKey: Keys.KeepDepartedAdvice) as? Bool ?? defaultKeepDepartedAdvice
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.KeepDepartedAdvice)
      HLTTUserDefaults.synchronize()
    }
  }
  
  public var firstLegRitNummers: [String] {
    get {
      return HLTTUserDefaults.object(forKey: Keys.FirstLegRitNummers) as? [String] ?? []
    }
    set {
      HLTTUserDefaults.set(newValue, forKey: Keys.FirstLegRitNummers)
      HLTTUserDefaults.synchronize()
    }
  }

  public var persistedAdvicesAndRequest: AdvicesAndRequest?

  public var appSettings: AppSettings {
    get {
      return AppSettings(rawValue: HLTTUserDefaults.integer(forKey: Keys.AppSettings))
    }
    set {
      HLTTUserDefaults.set(newValue.rawValue, forKey: Keys.AppSettings)
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
