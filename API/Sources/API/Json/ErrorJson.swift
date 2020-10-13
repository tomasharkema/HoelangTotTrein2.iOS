//
//  ErrorJson.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 23-01-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import Foundation

public struct ServerErrorJson {
  public let message: String?
  public let exceptionMessage: String?
  public let exceptionType: String?
  public let stackTrace: String?
}
