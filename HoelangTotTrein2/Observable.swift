//
//  Observable.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 27-09-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum

struct ObservableSubject<ValueType>: Equatable {
  let guid = NSUUID().UUIDString
  let observeOn: dispatch_queue_t
  let observable: (ValueType) -> Void
  let once: Bool
}

func == <ValueType>(lhs: ObservableSubject<ValueType>, rhs: ObservableSubject<ValueType>) -> Bool {
  lhs.guid == rhs.guid
}

class Observable<ValueType where ValueType: Equatable> {
  private let queue = dispatch_queue_create("nl.tomasharkema.Observable", DISPATCH_QUEUE_SERIAL)

  private var value: ValueType? {
    didSet {
      notifiy()
    }
  }

  private var subjects = [ObservableSubject<ValueType>]()

  private func notifiy() {
    if let value = value {
      for subject in subjects {
        dispatch_async(subject.observeOn) {
          subject.observable(value)
        }
        if subject.once {
          unsubscribe(subject)
        }
      }
    } else {
      print("Notifying without value?!")
    }
  }

  func subscribe(subject: (ValueType) -> Void) -> ObservableSubject<ValueType> {
    subscribe(dispatch_get_main_queue(), subject: subject)
  }

  func subscribe(observeOn: dispatch_queue_t, subject: (ValueType) -> Void) -> ObservableSubject<ValueType> {
    var subscription: ObservableSubject<ValueType>!
    dispatch_sync(queue) { [weak self] in
      subscription = ObservableSubject(observeOn: observeOn, observable: subject, once: false)
      self?.subjects.append(subscription)

      if let value = self?.value {
        dispatch_async(observeOn) {
          subject(value)
        }
      }
    }
    return subscription
  }

  func unsubscribe(subject: ObservableSubject<ValueType>) {
    dispatch_async(queue) { [weak self] in
      if let index = self?.subjects.indexOf(subject) {
        self?.subjects.removeAtIndex(index)
      }
    }
  }

  func next(value: ValueType) {
    dispatch_sync(queue) { [weak self] in
      if value != self?.value {
        self?.value = value
      }
    }
  }

  init() {}

  init(initialValue: ValueType) {
    value = initialValue
  }
}

// MARK: Once Trigger

extension Observable {
  func once(observeOn: dispatch_queue_t = dispatch_get_main_queue(), subject: (ValueType) -> Void) -> ObservableSubject<ValueType> {
    var subscription: ObservableSubject<ValueType>!
    dispatch_sync(queue) { [weak self] in
      subscription = ObservableSubject(observeOn: observeOn, observable: subject, once: true)
      self?.subjects.append(subscription)
    }

    return subscription
  }
}

// MARK: Monad 🤓

extension Observable {
  func map<NewValueType>(transform: ValueType -> NewValueType) -> (mapSubscription: ObservableSubject<ValueType>, newObservable: Observable<NewValueType>) {
    let newObservable = Observable<NewValueType>()

    let subscription = subscribe {
      newObservable.next(transform($0))
    }

    return (subscription, newObservable)
  }

  func mapOnce<NewValueType>(transform: ValueType -> NewValueType) -> (mapSubscription: ObservableSubject<ValueType>, newPromise: Promise<NewValueType, NoError>) {
    let promise = PromiseSource<NewValueType, NoError>()

    let subscription = once {
      promise.resolve(transform($0))
    }

    return (subscription, promise.promise)
  }

  func flatMap<NewValueType>(transfrom: ValueType -> Observable<NewValueType>) -> (flatMapSubscription: ObservableSubject<ValueType>, newObservable: Observable<NewValueType>) {
    let newObservable = Observable<NewValueType>()

    let subscription = subscribe {
      transfrom($0).once {
        newObservable.next($0)
      }
    }

    return (subscription, newObservable)
  }
}
