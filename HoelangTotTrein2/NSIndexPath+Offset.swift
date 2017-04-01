//
//  NSIndexPath+Offset.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension IndexPath {
  func section(_ inc: Int) -> IndexPath {
    return IndexPath(row: row, section: section + inc)
  }
}
