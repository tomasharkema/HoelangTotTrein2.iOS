//
//  LogService.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

enum LogLevel: Int {
  case DEBUG = 0
  case INFO
  case WARN
  case ERROR

  func shortCode() -> String {
    switch (self) {
    case .DEBUG:
      return "D"
    case .INFO:
      return "I"
    case .WARN:
      return "W"
    case .ERROR:
      return "E"
    }
  }
}

func log(level: LogLevel, section: String, message: String) {
  if level.rawValue >= LogService.logLevel.rawValue {
    let currentThreadId = pthread_mach_thread_np(pthread_self())
    print("[\(level.shortCode())/\(section)/T:\(currentThreadId)] \(message)")
  }
}

class LogService {
  private struct Holder {
    static var logLevel = LogLevel.ERROR
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