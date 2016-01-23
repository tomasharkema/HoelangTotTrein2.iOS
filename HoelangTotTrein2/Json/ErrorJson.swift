//
//  ErrorJson.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

struct ServerErrorJson {
  let message: String?
  let exceptionMessage: String?
  let exceptionType: String?
  let stackTrace: String?
}
