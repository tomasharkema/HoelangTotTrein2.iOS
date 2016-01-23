//
//  Array+Extensions.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}
