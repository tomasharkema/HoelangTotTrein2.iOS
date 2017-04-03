//
//  LogService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

enum LogLevel: Int {
  case debug = 0
  case info
  case warn
  case error

  func shortCode() -> String {
    switch (self) {
    case .debug:
      return "D"
    case .info:
      return "I"
    case .warn:
      return "W"
    case .error:
      return "E"
    }
  }
}

func log(_ level: LogLevel, section: String, message: String) {
  if level.rawValue >= LogService.logLevel.rawValue {
    let currentThreadId = pthread_mach_thread_np(pthread_self())
    print("[\(level.shortCode())/\(section)/T:\(currentThreadId)] \(message)")
  }
}

class LogService {
  fileprivate struct Holder {
    static var logLevel = LogLevel.error
  }

  class var logLevel: LogLevel {
    get {
    return Holder.logLevel
    }
    set {
      Holder.logLevel = newValue
    }
  }
}
