//
//  Array+Helpers.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

extension Array {
  func skip(_ count:Int) -> [Element] {
    return [Element](self[count..<self.count])
  }
}
