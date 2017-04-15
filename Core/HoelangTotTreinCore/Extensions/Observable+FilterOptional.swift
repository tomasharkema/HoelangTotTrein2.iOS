
//
//  Observable+FilterOptional.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 10-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation
import RxSwift

public protocol OptionalType {
  associatedtype T
  func intoOptional() -> T?
}

extension Optional : OptionalType {
  public func intoOptional() -> Wrapped? {
    return self.flatMap {$0}
  }
}


extension Observable where Element: OptionalType {
  public func filterOptional() -> Observable<Element.T> {
    return self.map { $0.intoOptional() }
      .filter { $0 != nil }
      .map { $0! }
  }
}
