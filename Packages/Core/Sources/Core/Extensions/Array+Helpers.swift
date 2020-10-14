//
//  Array+Helpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

extension Array {
  public func skip(_ count: Int) -> [Element] {
    [Element](self[count ..< self.count])
  }
}
