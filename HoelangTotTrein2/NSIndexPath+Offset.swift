//
//  NSIndexPath+Offset.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 03-10-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension NSIndexPath {
  func section(inc: Int) -> NSIndexPath {
    return NSIndexPath(forRow: row, inSection: section + inc)
  }
}