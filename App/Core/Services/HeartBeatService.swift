//
//  HeartBeatService.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 30-07-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation

class WeakReference<ReferenceType: AnyObject> {
  weak var reference: ReferenceType?
  init(_ reference: ReferenceType) {
    self.reference = reference
  }
}

/// Some tryout shared timer heartbeat service
public class HeartBeat {

  private let lock = NSLock()
  private var timer: Timer?

  private var registeredTokens = [WeakReference<Token>]() {
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

    let token = Token(rawValue: UUID(), type: type, callback: callback)

    registeredTokens.append(WeakReference(token))

    return token
  }

  public func unregister(token: Token) {
    lock.lock(); defer { lock.unlock() }

    registeredTokens = registeredTokens.filter {
      $0.reference != token
    }
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
    var tokensToUnregister = [WeakReference<Token>]()
    for tokenReference in registeredTokens {
      guard let element = tokenReference.reference else {
        tokensToUnregister.append(tokenReference)
        break
      }

      switch element.type {
      case .deadline(let date):
        if callDate > date {
          element.callback(callDate)
          tokensToUnregister.append(tokenReference)
        }

      case .repeating(let interval):
        if Int(callDate.timeIntervalSince1970) % Int(interval) == 0 {
          element.callback(callDate)
        }

      case .single:
        element.callback(callDate)
        tokensToUnregister.append(tokenReference)
      }
    }
    
    tokensToUnregister.forEach { reference in
      registeredTokens = registeredTokens.filter {
        $0 !== reference
      }
    }
  }

}

extension HeartBeat {
  public class Token: Equatable, Hashable {
    private let rawValue: UUID
    fileprivate let type: TickType
    fileprivate let callback: HeartBeatCallback

    init(rawValue: UUID, type: TickType, callback: @escaping HeartBeatCallback) {
      self.rawValue = rawValue
      self.type = type
      self.callback = callback
    }

    public var hashValue: Int {
      return rawValue.hashValue
    }

    public static func ==(lhs: Token, rhs: Token) -> Bool {
      return lhs.rawValue == rhs.rawValue
    }

    deinit {
      print("DEINIT!")
    }
  }

  public typealias HeartBeatCallback = (Date) -> Void

  public enum TickType {
    case repeating(interval: TimeInterval)
    case single
    case deadline(date: Date)
  }

//  class Subject {
//    let type: TickType
//    let token: Token
//    let callback: HeartBeatCallback
//
//    init(type: TickType, token: Token, callback: @escaping HeartBeatCallback) {
//      self.type = type
//      self.token = token
//      self.callback = callback
//    }
//  }
}
