//
//  Observable.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct ObservableSubject<T>: Equatable {
  let guid = NSUUID().UUIDString
  let observeOn: dispatch_queue_t
  let observable: (T) -> ()
}

func ==<T>(lhs: ObservableSubject<T>, rhs: ObservableSubject<T>) -> Bool {
  return lhs.guid == rhs.guid
}

class Observable<T where T: Equatable> {

  private let queue = dispatch_queue_create("nl.tomasharkema.Observable", DISPATCH_QUEUE_SERIAL)

  private var value: T? = nil {
    didSet {
      notifiy()
    }
  }
  
  private var subjects = [ObservableSubject<T>]()

  private func notifiy() {
    dispatch_async(queue) { [weak self] in
      if let value = self?.value, subjects = self?.subjects {
        for subject in subjects {
          dispatch_async(subject.observeOn) {
            subject.observable(value)
          }
        }
      } else {
        print("Notifying without value?!")
      }
    }
  }

  func subscribe(observeOn: dispatch_queue_t = dispatch_get_main_queue(), subject: (T) -> ()) -> ObservableSubject<T> {
    var subscription: ObservableSubject<T>!
    dispatch_sync(queue) { [weak self] in
      subscription = ObservableSubject(observeOn: observeOn, observable: subject)
      self?.subjects.append(subscription)
    }
    if let value = value {
      dispatch_async(observeOn) {
        subject(value)
      }
    }
    return subscription
  }

  func unsubscribe(subject: ObservableSubject<T>) {
    dispatch_async(queue) { [weak self] in
      if let index = self?.subjects.indexOf(subject) {
        self?.subjects.removeAtIndex(index)
      }
    }
  }

  func next(value: T) {
    dispatch_async(queue) { [weak self] in
      if value != self?.value {
        self?.value = value
      }
    }
  }

  init() {}

  init(initialValue: T) {
    value = initialValue
  }
}