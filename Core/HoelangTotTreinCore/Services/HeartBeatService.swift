//
//  HeartBeatService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 30-07-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation

/// Some tryout shared timer heartbeat service
public class HeartBeat {

  private let lock = NSLock()
  private var timer: Timer?

  private var registeredTokens = [Token: Subject]() {
    didSet {
      registerTimer()
    }
  }
  public var isSuspended = false {
    didSet {
      lock.lock(); defer { lock.unlock() }
      registerTimer()
    }
  }

  public init() { }

  public func register(type: TickType, callback: @escaping HeartBeatCallback) -> Token {
    lock.lock(); defer { lock.unlock() }

    let token = Token(rawValue: UUID())

    registeredTokens[token] = Subject(type: type, callback: callback)

    return token
  }

  public func unregister(token: Token) {
    lock.lock(); defer { lock.unlock() }

    registeredTokens[token] = nil
  }

  private func registerTimer() {
    if registeredTokens.isEmpty || isSuspended {
      timer?.invalidate()
      timer = nil
    } else if timer == nil {
      timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
      timer?.tolerance = 0.1
    }
  }

  @objc private func tick() {
    lock.lock(); defer { lock.unlock() }

    let callDate = Date()
    var tokensToUnregister = [Token]()
    registeredTokens.forEach { item in

      switch item.value.type {
      case .deadline(let date):
        if callDate > date {
          item.value.callback(callDate)
          tokensToUnregister.append(item.key)
        }

      case .repeating(let interval):
        if Int(callDate.timeIntervalSince1970) % Int(interval) == 0 {
          item.value.callback(callDate)
        }

      case .single:
        item.value.callback(callDate)
        tokensToUnregister.append(item.key)
      }
    }

    tokensToUnregister.forEach {
      registeredTokens.removeValue(forKey: $0)
    }
  }

}

extension HeartBeat {
  public struct Token: RawRepresentable, Hashable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
      self.rawValue = rawValue
    }
  }

  public typealias HeartBeatCallback = (Date) -> Void

  public enum TickType {
    case repeating(interval: TimeInterval)
    case single
    case deadline(date: Date)
  }

  struct Subject {
    let type: TickType
    let callback: HeartBeatCallback
  }
}
