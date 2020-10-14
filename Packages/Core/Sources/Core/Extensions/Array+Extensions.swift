//
//  Array+Extensions.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

extension Array {
  public subscript(safe index: Int) -> Element? {
    indices ~= index ? self[index] : nil
  }
}

prefix operator <!>

public prefix func <!> <T>(array: [T?]) -> [T] {
  array.filter { $0 != nil }.map { $0! }
}
