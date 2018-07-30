//
//  DisposeBagContainer+Variable.swift
//  HoelangTotTreinCore
//
//  Created by Tomas Harkema on 30-07-18.
//  Copyright © 2018 Tomas Harkema. All rights reserved.
//

import Foundation
import Bindable

//public protocol Bindable: class {
//  var disposeBag: DisposeBag { get }
//  var subscriptions: [AnyKeyPath: Subscription] { get set }
//}
//
//extension Bindable {
//  public func bind<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, to variable: Variable<T>) {
//    subscriptions[keyPath]?.unsubscribe()
//    subscriptions[keyPath] = nil
//
//    self[keyPath: keyPath] = variable.value
//    let subscription = variable.subscribe { [weak self] event in
//      self?[keyPath: keyPath] = event.value
//    }
//
//    disposeBag.insert(subscription)
//    subscriptions[keyPath] = subscription
//  }
//
//  public func bind<T>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, to variable: Variable<T>?) {
//    subscriptions[keyPath]?.unsubscribe()
//    subscriptions[keyPath] = nil
//
//    if let variable = variable {
//      self[keyPath: keyPath] = variable.value
//      let subscription = variable.subscribe { [weak self] event in
//        self?[keyPath: keyPath] = event.value
//      }
//      disposeBag.insert(subscription)
//      subscriptions[keyPath] = subscription
//    } else {
//      self[keyPath: keyPath] = nil
//    }
//  }
//
//  public func unbind<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, resetTo value: T) {
//    subscriptions[keyPath]?.unsubscribe()
//    subscriptions[keyPath] = nil
//
//    self[keyPath: keyPath] = value
//  }
//
//  public func unbind<T>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, resetTo value: T? = nil) {
//    subscriptions[keyPath]?.unsubscribe()
//    subscriptions[keyPath] = nil
//
//    self[keyPath: keyPath] = value
//  }
//}
