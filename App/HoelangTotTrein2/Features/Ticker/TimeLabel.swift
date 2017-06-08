//
//  TimeLabel.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 07-06-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import RxSwift

protocol Updatable {
  func update()
}

private class TimeLabelCoordinator {
  static var shared = TimeLabelCoordinator()

  private var timer: Disposable?

  private var subjects = [(UIView & Updatable)]()

  func attach(updatable: (UIView & Updatable)) {
    subjects.append(updatable)

    resetIfNeeded()
  }

  func remove(updatable: (UIView & Updatable)) {
    if let index = subjects.index(where: { view -> Bool in
      view === updatable
    }) {
      subjects.remove(at: index)
    }

    resetIfNeeded()
  }

  private func resetIfNeeded() {
    if subjects.isEmpty {
      timer?.dispose()
    } else {

      if timer != nil {
        return
      }

      timer = Observable<Int>.interval(0.2, scheduler: MainScheduler.asyncInstance)
        .subscribe { [weak self] _ in
          self?.subjects.forEach { (updatable: (UIView & Updatable)) in
            updatable.update()
          }
        }
    }
  }
}

enum TimeFormat {
  case h
  case m
  case s
  case customString(String)
}

class TimeLabel: UILabel {

  private var disposeBag: DisposeBag?

  var autoStart = true

  var format: [TimeFormat] = []

  var date: Date? {
    didSet {
      if date != nil {

        if oldValue == date {
          stopTimer()
        }

        if autoStart {
          startTimer()
        }
      } else {
        stopTimer()
      }
    }
  }

  func startTimer() {
    TimeLabelCoordinator.shared.attach(updatable: self)
  }

  func stopTimer() {
    TimeLabelCoordinator.shared.remove(updatable: self)
  }

  private func component(forFormat format: TimeFormat, toDate date: Date) -> Int? {

    let components = Calendar.current.dateComponents([.hour, .minute, .second], from: Date(), to: date)
    switch format {
    case .h:
      return components.hour
    case .m:
      return components.minute
    case .s:
      return components.second
    default:
      return nil
    }
  }

  private func stringFormat(forFormat format: TimeFormat) -> String {
    switch format {
    case .h:
      return "%01d"
    case .m, .s:
      return "%02d"
    case .customString:
      return "%@"
    }
  }

  private func render() {
    guard let date = date else {
      return
    }

    let newText = format.reduce("") { (prev, format) -> String in
      if case .customString(let string) = format {
        return prev + string
      }

      guard let component = component(forFormat: format, toDate: date) else {
        return prev
      }

      return prev + String(format: stringFormat(forFormat: format), component)
    }

    text = newText
  }

}

extension TimeLabel: Updatable {
  func update() {
    render()
  }
}
